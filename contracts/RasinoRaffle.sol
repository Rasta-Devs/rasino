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

    using SafeMath for uint256;
    using Math for uint256;
    using SafeMath for uint8;
    using Math for uint8;

    IERC20private _token = IERC20(0xe3e8cc42da487d1116d26687856e9fb684817c52); // RASTA by default
    string public description;
    uint256 _burnFee = 100; // Burns at settlement, out of 10000
    uint256 _devFee = 200; // Man, we devs gotta feed our children.
    uint256 pricePerTicket = 1000000000000000000; // One RASTA

    mapping(uint => uint) public roundSupply;
    uint public round;

    address[] tickets;
    mapping(address => TicketHolderPosition) public userMemo;


    event TicketBought(address from);

    /**
     * @dev Constructor sets token that can be received and oracle to determine price. 
     */
    constructor (address token, string memory _description) public {
        _token = IERC20(token);
        description = _description;
    }

    /**
     * @dev Sets both burn, dev and  fees
     */
    function setFees(uint256 burnFee, uint256 devFee) external onlyOwner{
        _burnFee = burnFee;
        _devFee = devFee;
    }

    /**
     * @dev Claim earnings for winner
     */
    function _claimEarnings(address account) internal {
        // TODO: calculate and dispurse winnings

        delete userMemo[from];
    }

    /**
     * @dev Buy Tickets
     */
    function buyTicket(uint256 amount) external {
        address from = _msgSender();
        uint cost = amount.mul(pricePerTicket);

        /* Buy tickets */
        uint256 allowance = _token.allowance(from, address(this));
        require(allowance >= cost, "Check the token allowance");
        require(_token.transferFrom(from, address(this), cost));

        if(userMemo[from].isValue){
            if(userMemo[from].round != round){
                _claimEarnings(from);
            }
        }else{
            userMemo[from] = TicketHolderPosition(round, []);
        }

        while(amount > 0){
            tickets.push(from);
        }


    }

    /**
     * @dev Start Jackpot
     */
    function startJackpot(uint256 amount, uint256 timeOffset, uint commit, uint256 price) external onlyOwner{
        address from = _msgSender();
        

        /* Step one -- Transfer Tokens */
        uint256 allowance = _token.allowance(from, address(this));
        require(allowance >= amount, "Check the token allowance");
        require(_token.transferFrom(from, address(this), amount));

    }

}