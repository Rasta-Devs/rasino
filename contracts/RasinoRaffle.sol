// SPDX-License-Identifier: MIT
pragma solidity ^0.6.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Math.sol";


/**
 * @title RasinoRaffle
 * @dev A simple raffle for Rastas
 */
contract RasinoRaffle is Ownable {
    struct TicketHolderPosition {
        uint ticketAmount;
        uint ticketNumber;
    }

    struct TicketHolderRecord { 
        uint round;
        TicketHolderPosition[] record;
    }
    struct Round { 
        uint roundSupply;
        bytes32 commit;
        uint256 pricePerTicket;
        bool collected;
    }

    using SafeMath for uint256;
    using Math for uint256;
    using SafeMath for uint8;
    using Math for uint8;

    IERC20private _token = IERC20(0xe3e8cc42da487d1116d26687856e9fb684817c52); // RASTA by default
    string public description;
    uint256 _devFee = 300; // Man, we devs gotta feed our children.
    address _devAddress;
    uint256 _ticketFee = 2200; // 22 percent goes back to the community
    uint pot = 0;

    Round[] rounds = [];

    address[] tickets = [];
    mapping(address => TicketHolderPosition) public userMemo;

    /**
     * @dev Constructor
     */
    constructor (address token, address devAddress, string memory _description) public {
        _token = IERC20(token);
        description = _description;
        _devAddress = devAddress;
    }

    /**
     * @dev Sets both dev and ticket fees
     */
    function setFees(uint256 ticketFee, uint256 devFee) external onlyOwner{
        _ticketFee = ticketFee;
        _devFee = devFee;
    }

    /**
     * @dev Claim earnings for ticket holders
     */
    function _claimEarnings(address account) internal {
        require(userMemo[account].isValue);
        require(userMemo[account].round < rounds.length); // must be a past round
        require(rounds[userMemo[account].round].collected);
        
        uint rid = userMemo[account].round;
        uint earnings = 0;

        for (uint256 index = 0; index < userMemo[account].record.length; index++) {
            TicketHolderPosition position =  userMemo[account].record[index];
            uint ticketsBoughtAfterward = rounds[rid].roundSupply.sub(position.ticketNumber);
            uint feeForTicketHolders = ticketsBoughtAfterward.mul(rounds[rid].pricePerTicket).mul(_ticketFee).div(10000);
            uint earningsForThisTicketPosition = feeForTicketHolders.mul(position.ticketAmount).div(position.ticketNumber);
            earnings = earnings.add(earningsForThisTicketPosition);
        }
        require(_token.transfer(account, earnings));
        delete userMemo[account];
    }

    /**
     * @dev Buy Tickets
     */
    function buyTicket(uint256 amount) external {
        require(rounds[userMemo[account].round].collected == false);
        uint roundId = rounds.length.sub(1);
        address from = _msgSender();
        uint cost = amount.mul(pricePerTicket);

        /* Buy tickets */
        uint256 allowance = _token.allowance(from, address(this));
        require(allowance >= cost, "Check the token allowance");
        require(_token.transferFrom(from, address(this), cost));

        if(userMemo[from].isValue){
            if(userMemo[from].round != roundId){
                _claimEarnings(from);
                userMemo[from] = TicketHolderPosition(roundId, []);
            }
        }else{
                userMemo[from] = TicketHolderPosition(roundId, []);
        }
        uint256 i = amount;
        while(i > 0){
            tickets.push(from);
            i = i.sub(1);
        }
        uint newPot = pot.add(amount.mul(uint256(10000).sub(_ticketFee).sub(_devFee)).div(10000));
        uint devAmount = amount.mul(_devFee).div(10000);
        require(_token.transfer(_devAddress, devAmount));

        pot = newPot;
        userMemo[from].record.push(TicketHolderPosition(amount, tickets.length));

    }

    /**
     * @dev Start Jackpot
     */
    function startJackpot(bytes32 commit, uint256 price) external onlyOwner{
        require(rounds[rounds.length.sub(1)].collected); // last round must have finished

        tickets = [];
        pot = 0;
        rounds.push(Round(0, commit, price, false));
        
    }
    /**
     * @dev Stop Jackpot
     */
    function stopJackpot(uint answer) external onlyOwner{
        Round currentRound = rounds[rounds.length.sub(1)];
        require(currentRound.collected == false); // last round must have finished
        require(abi.encodePacked(answer) == currentRound.commit); // Check that the hash matches

        uint winner = answer.mod(tickets.length);

        require(_token.transfer(tickets[winner], pot));
        rounds[rounds.length.sub(1)].collected = true;
    }

}