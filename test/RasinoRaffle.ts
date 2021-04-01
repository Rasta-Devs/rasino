import { ethers } from "hardhat";
import chai from "chai";
import { solidity, MockProvider } from "ethereum-waffle";
import { RasinoRaffle, RasinoRaffle__factory, MockToken, MockToken__factory } from "../typechain";
import { sign, Signer } from "crypto";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { BigNumber } from "ethers";
const { singletons, expectRevert } = require('@openzeppelin/test-helpers');
// const provider = new MockProvider();
// const accounts = provider.getWallets()

chai.use(solidity);
const { expect } = chai;
var signers: SignerWithAddress[] = [];

const TICKET_PRICE = BigNumber.from(1e10).mul(1e8);
const STARTING_AMOUNT = BigNumber.from(1e10).mul(1e11);

describe("RasinoRaffle", () => {
  let RasinoRaffle: RasinoRaffle;
  let MockToken: MockToken;

  beforeEach(async () => {
    // 1
    signers = await ethers.getSigners();
    // console.log(signers.map(t=> t.address))
    await singletons.ERC1820Registry(signers[0].address);
    // 2 Deploy Raffle
    const mockTokenFactory = (await ethers.getContractFactory(
      "MockToken",
      signers[0]
    )) as MockToken__factory;
    const raffleFactory = (await ethers.getContractFactory(
      "RasinoRaffle",
      signers[0]
    )) as RasinoRaffle__factory;
    MockToken = await mockTokenFactory.deploy(STARTING_AMOUNT, signers[0].address);
    await MockToken.deployed();
    RasinoRaffle = await raffleFactory.deploy(MockToken.address, signers[0].address, signers[3].address, "Sample Description");
    await RasinoRaffle.deployed();


    // 3 Deploy Price Oracle
    await MockToken.mint(signers[1].address, STARTING_AMOUNT);
    await MockToken.mint(signers[2].address, STARTING_AMOUNT);

      console.log("LOG: Deployed all Contracts")

      // Approve contract on both accounts 
      await MockToken.connect(signers[1]).approve(RasinoRaffle.address, STARTING_AMOUNT)
      await MockToken.connect(signers[2]).approve(RasinoRaffle.address, STARTING_AMOUNT)
      await MockToken.connect(signers[0]).approve(RasinoRaffle.address, STARTING_AMOUNT)
      console.log("LOG: Approved Contract for MockToken")

  });
  
  // 4
  describe("Rasino Raffle", async () => {
    it("Buy Ticket takes from account", async () => {
      let balance = (await MockToken.balanceOf(signers[1].address));
      await RasinoRaffle.startJackpot(TICKET_PRICE);
      await RasinoRaffle.connect(signers[1]).buyTicket(1);
      let newBalance = (await MockToken.balanceOf(signers[1].address));

      expect(newBalance).to.eq(balance.sub(TICKET_PRICE));
    });
    it("Dev Fees collected ", async () => {
      await RasinoRaffle.startJackpot(TICKET_PRICE);
      let balance = (await MockToken.balanceOf(signers[0].address));
      await RasinoRaffle.connect(signers[1]).buyTicket(10);
      let newBalance = (await MockToken.balanceOf(signers[0].address));

      expect(newBalance).to.eq(balance.add(TICKET_PRICE.mul(10).mul(300).div(10000)));
    });
    it("Pot Balance Transferred ", async () => {
      await RasinoRaffle.startJackpot(TICKET_PRICE);
      await RasinoRaffle.connect(signers[1]).buyTicket(10);
      await RasinoRaffle.connect(signers[2]).buyTicket(1);
      let potBalance = await RasinoRaffle.currentPot();
      let balance = (await MockToken.balanceOf(signers[2].address));
      await RasinoRaffle.stopJackpot(10);
      let newBalance = (await MockToken.balanceOf(signers[2].address));

      expect(newBalance).to.eq(balance.add(potBalance));
    });
    it("ClaimEarnings calculates correctly", async () => {
      await RasinoRaffle.startJackpot(TICKET_PRICE);
      await RasinoRaffle.connect(signers[1]).buyTicket(10);
      await RasinoRaffle.connect(signers[2]).buyTicket(90);
      await RasinoRaffle.stopJackpot(10);
      let earnings = (await RasinoRaffle.connect(signers[1]).estimateEarnings());

      expect(earnings.div(1e8).mul(1e8)).to.eq(BigNumber.from(1.9867979713e10).mul(1e8));
    });
  });
  
});
