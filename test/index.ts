import { expect } from "chai";
import { ethers } from "hardhat";

describe("NFT Marketplace", async () => {
  it("Should create the Contracts", async function () {
    const TestNFT = await ethers.getContractFactory("NFT");
    const Market = await ethers.getContractFactory("NFTMarketplace");

    const market = await Market.deploy();
    const nft = await TestNFT.deploy("MyToken", "TKN", "ABC.com");

    expect(market).to.not.equal(undefined);
    expect(nft).to.not.equal(undefined);
  });

  it("A user can update the service fee", async () => {
    const Market = await ethers.getContractFactory("NFTMarketplace");
    const market = await Market.deploy();

    market.setServiceFee(2000);
    const price = await market.getServiceFee();
    expect(price).to.equal(2000);
  });

  it("A user can list an NFT for sale, and return it.", async () => {
    const TestNFT = await ethers.getContractFactory("NFT");
    const Market = await ethers.getContractFactory("NFTMarketplace");

    const market = await Market.deploy();
    const nft = await TestNFT.deploy("MyToken", "TKN", "ABC.com");
    await nft.adminMint();
    await nft.approve(market.address, 1);

    await market.addItemToMarket(nft.address, 1, "1000000000000000000");

    const item = await market.getItem(1);
    expect(item.nftContract).to.equal(nft.address);
    expect(item.tokenId).to.equal(1);
  });

  it("A user can set the royalties for their NFT contracts.", async () => {
    const TestNFT = await ethers.getContractFactory("NFT");
    const Market = await ethers.getContractFactory("NFTMarketplace");
    const market = await Market.deploy();
    const nft = await TestNFT.deploy("MyToken", "TKN", "ABC.com");

    await market.setRoyalties(nft.address, 10);
    const royalties = await market.getRoyalties(nft.address);
    expect(royalties).to.equal(10);
  });

  it("A user can remove their NFTs from the marketplace.", async () => {
    const TestNFT = await ethers.getContractFactory("NFT");
    const Market = await ethers.getContractFactory("NFTMarketplace");
    const [owner] = await ethers.getSigners();
    const market = await Market.deploy();
    const nft = await TestNFT.deploy("MyToken", "TKN", "ABC.com");
    await nft.adminMint();
    await nft.approve(market.address, 1);
    await market.addItemToMarket(nft.address, 1, 1);

    await market.cancelSaleFromMarket(1);
    const token = await nft.balanceOf(owner.address);
    const item = await market.getItem(1);
    expect(item.forSale).to.equal(false);
    expect(token).to.equal(1);
  });

  it("A User can buy an NFT from the market", async () => {
    const TestNFT = await ethers.getContractFactory("NFT");
    const Market = await ethers.getContractFactory("NFTMarketplace");
    const [owner] = await ethers.getSigners();
    const market = await Market.deploy();
    const nft = await TestNFT.deploy("MyToken", "TKN", "ABC.com");
    await nft.adminMint();
    await nft.approve(market.address, 1);
    await market.addItemToMarket(nft.address, 1, 1);
    await market.buyItem(1, { value: "1000000000000000000" });
    const count = await nft.balanceOf(owner.address);
    expect(count).to.equal(1);
  });
});
