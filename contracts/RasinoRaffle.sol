// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


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
        bool isValue;
        TicketHolderPosition[] record;
    }
    struct Round { 
        uint roundSupply;
        bytes commit;
        uint256 pricePerTicket;
        bool collected;
    }

    using SafeMath for uint256;
    using Math for uint256;
    using SafeMath for uint8;
    using Math for uint8;

    IERC20 private _token = IERC20(0xE3e8cC42DA487d1116D26687856e9FB684817c52); // RASTA by default
    string public description;
    uint256 _devFee = 300; // Man, we devs gotta feed our children.
    address _devAddress;
    uint256 _ticketFee = 2200; // 22 percent goes back to the community
    uint pot = 0;

    Round[] rounds;

    address[] tickets;
    mapping(address => TicketHolderRecord) public userMemo;

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
            TicketHolderPosition memory position =  userMemo[account].record[index];
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
        uint roundId = rounds.length.sub(1);
        require(rounds[roundId].collected == false);
        address from = _msgSender();
        uint cost = amount.mul(rounds[roundId].pricePerTicket);

        /* Buy tickets */
        uint256 allowance = _token.allowance(from, address(this));
        require(allowance >= cost, "Check the token allowance");
        require(_token.transferFrom(from, address(this), cost));

        if(userMemo[from].isValue){
            if(userMemo[from].round != roundId){
                _claimEarnings(from);
                userMemo[from].round = roundId;
            }
        }else{
                userMemo[from].round = roundId;
        }
        userMemo[from].isValue = true;
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
    function startJackpot(bytes calldata commit, uint256 price) external onlyOwner{
        require(rounds[rounds.length.sub(1)].collected); // last round must have finished

        tickets = new address[](0);
        pot = 0;
        rounds.push(Round(0, commit, price, false));
        
    }
    /**
     * @dev Stop Jackpot
     */
    function stopJackpot(uint answer) external onlyOwner{
        Round memory currentRound = rounds[rounds.length.sub(1)];
        require(currentRound.collected == false); // last round must have finished
        //require(uint(abi.encodePacked(answer)) == uint(currentRound.commit)); // Check that the hash matches
        //TODO: somehow compare those commits. May need more research

        uint winner = answer.mod(tickets.length);

        require(_token.transfer(tickets[winner], pot));
        rounds[rounds.length.sub(1)].collected = true;
    }

}