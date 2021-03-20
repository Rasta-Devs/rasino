import { ethers } from "hardhat";
import chai from "chai";
import { solidity, MockProvider } from "ethereum-waffle";
import { KUDIPriceOracleDAI__factory, KUDIPriceOracleDAI, EURUSD__factory, EURUSD, EURXOF__factory, EURXOF, MockTokenPriceFeed__factory, MockTokenPriceFeed } from "../typechain";
import { sign, Signer } from "crypto";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { BigNumber } from "ethers";
const { singletons, expectRevert } = require('@openzeppelin/test-helpers');
// const provider = new MockProvider();
// const accounts = provider.getWallets()

chai.use(solidity);
const { expect } = chai;
var signers: SignerWithAddress[] = [];

describe("PriceOracle", () => {
  let EURUSDPriceFeed: EURUSD;
  let EURXOFPriceFeed: EURXOF;
  let MockTokenPriceFeed: MockTokenPriceFeed;
  let KUDIPriceFeed: KUDIPriceOracleDAI;

  beforeEach(async () => {
    // 1
    signers = await ethers.getSigners();
    // console.log(signers.map(t=> t.address))
    await singletons.ERC1820Registry(signers[0].address);
    // 2 Deploy Price Feeds
    const eurUSDFactory = (await ethers.getContractFactory(
      "EURUSD",
      signers[0]
    )) as EURUSD__factory;
    const eurXOFFactory = (await ethers.getContractFactory(
      "EURXOF",
      signers[0]
    )) as EURXOF__factory;
    const mockTokenPriceFeedFactory = (await ethers.getContractFactory(
      "MockTokenPriceFeed",
      signers[0]
    )) as MockTokenPriceFeed__factory;
    EURUSDPriceFeed = await eurUSDFactory.deploy();
    EURXOFPriceFeed = await eurXOFFactory.deploy();
    MockTokenPriceFeed = await mockTokenPriceFeedFactory.deploy();
    await EURUSDPriceFeed.deployed();
    await EURXOFPriceFeed.deployed();
    await MockTokenPriceFeed.deployed();


    // 3 Deploy Price Oracle
    const priceOracleFactory = (await ethers.getContractFactory(
      "KUDIPriceOracleDAI",
      signers[0]
    )) as KUDIPriceOracleDAI__factory;
    KUDIPriceFeed = await priceOracleFactory.deploy(MockTokenPriceFeed.address, EURUSDPriceFeed.address, EURXOFPriceFeed.address);
    await KUDIPriceFeed.deployed();

  });

  // 4
  describe("PriceFeed", async () => {
    it("price is what expected", async () => {
      let price = (await KUDIPriceFeed.price()).toNumber();
      expect(price).to.eq(Math.floor(1.5e18*0.000001524490/1.18500154));
    });
  });
  
});
