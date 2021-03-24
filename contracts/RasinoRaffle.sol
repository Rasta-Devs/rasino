// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Math.sol";


/**
 * @title RasinoRaffle
 * @dev A simple raffle for Rastas
 */
contract RasinoRaffle is Ownable {

    struct TicketHolderRecord { 
        uint round;
        bool isValue;
        uint amount;
        uint position;
    }
    struct Round { 
        uint roundSupply;
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
     * @dev Claim earnings for sender
     */
    function claimEarnings() external {
        address from = _msgSender();
        _claimEarnings(from);
    }
    /**
     * @dev Claim earnings for ticket holders
     */
    function _claimEarnings(address account) internal {
        uint earnings = _estimateEarnings(account);
        require(_token.transfer(account, earnings));
        delete userMemo[account];
    }

    function _estimateEarnings(address account) internal view returns(uint) {
        
        require(userMemo[account].isValue);
        require(userMemo[account].round < rounds.length); // must be a past round
        require(rounds[userMemo[account].round].collected);
        
        uint rid = userMemo[account].round;

        uint position =  userMemo[account].position;
        uint amount =  userMemo[account].amount;
        uint256 totalDividedByNumber = rounds[rid].roundSupply.div(position);
        uint earningsForThisTicketPosition = RastaMath.log_2(totalDividedByNumber).mul(amount).mul(rounds[rid].pricePerTicket).mul(_ticketFee).div(10000).mul(0x4D104D427DE7FC000000000000000000) >> 128;
        return earningsForThisTicketPosition;
    }
    function estimateEarnings() external view returns(uint){
        address from = _msgSender();
        return _estimateEarnings(from);

    }

    /**
     * @dev Buy Tickets
     */
    function buyTicket(uint256 amount) external {
        uint roundId = rounds.length.sub(1);
        require(rounds[roundId].collected == false);
        address from = _msgSender();
        uint pricePerTicket = rounds[roundId].pricePerTicket;
        uint cost = amount.mul(pricePerTicket);

        /* Buy tickets */
        uint256 allowance = _token.allowance(from, address(this));
        require(allowance >= cost, "Check the token allowance");
        require(_token.transferFrom(from, address(this), cost));

        if(userMemo[from].isValue){
            if(userMemo[from].round != roundId){
                _claimEarnings(from);
                userMemo[from] = TicketHolderRecord(roundId, true, 0, 0);
            }
        }else{
                userMemo[from].round = roundId;
                userMemo[from] = TicketHolderRecord(roundId, true, 0, 0);
        }
        userMemo[from].isValue = true;
        uint256 i = amount;
        while(i > 0){
            tickets.push(from);
            i = i.sub(1);
        }
        uint newPot = pot.add(cost.mul(uint256(10000).sub(_ticketFee).sub(_devFee)).div(10000));
        uint devAmount = cost.mul(_devFee).div(10000);
        require(_token.transfer(_devAddress, devAmount));

        rounds[roundId].roundSupply = rounds[roundId].roundSupply.add(amount);
        pot = newPot;
        uint totalPosition = tickets.length.add(userMemo[from].position);
        uint weightedCurrent = userMemo[from].amount.mul(userMemo[from].position);
        uint weightedNew = amount.mul(tickets.length);
        userMemo[from].position = weightedCurrent.add(weightedNew).div(totalPosition).add(1).min(tickets.length);
        userMemo[from].amount = userMemo[from].amount.add(amount);

    }

    /**
     * @dev Start Jackpot
     */
    function startJackpot(uint256 price) external onlyOwner{
        require(rounds.length == 0 || rounds[rounds.length.sub(1)].collected); // last round must have finished

        tickets = new address[](0);
        pot = 0;
        rounds.push(Round(0, price, false));
        
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
    
    /**
     * @dev Current Pot Amount
     */
    function currentPot() external onlyOwner  view returns(int){
        if(rounds.length == 0){
            return -1;
        }
        Round memory currentRound = rounds[rounds.length.sub(1)];
        if(currentRound.collected){
            return -1;
        }
        return int(pot);
    }
}