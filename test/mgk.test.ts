// /*
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
import { expect } from "chai";
import { ethers } from "hardhat";
import mgkAbi from "../artifacts/contracts/MGK.sol/MGK.json";

describe("MGK", function () {
  let owner;
  let user1;
  let mgk;
  let contract;

  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();

    const MGK = await ethers.getContractFactory("MGK", owner);
    mgk = await MGK.deploy("Liquid Access", "LANFT", 5, "The Merchant");
    await mgk.deployed();

    contract = new ethers.Contract(mgk.address, mgkAbi.abi, owner);
  });

  it("Get owner:", async function () {
    console.log("owner", owner.address);
    expect(owner.address).to.be.properAddress;
  });

  // it("Get name:", async function () {
  //   const name = await mgk.name();
  //   expect(name).to.eq("Liquid Access");
  //   console.log("name:", name);
  // });

  it("Get Merchant name:", async function () {
    const merchantName = await mgk.merchantName();
    expect(merchantName).to.eq("The Merchant");
    console.log("Merchant name:", merchantName);
  });

  it("Handle NFT Black List:", async function () {
    await mgk.addNFTToBlackList("1");
    await mgk.addNFTToBlackList("22");
    console.log("Add two NFTs to the black list (1, 22)");

    const nft_1_2_ = await mgk.getNFTFromBlacklist("1");
    const nft_22_2_ = await mgk.getNFTFromBlacklist("22");
    console.log("Got NFTs from the black list:", nft_1_2_, nft_22_2_);

    await mgk.removeNFTFromBlackList("1");
    console.log("Remove NFT from the black list (1)");

    const nft_1_ = await mgk.getNFTFromBlacklist("1");
    const nft_22_ = await mgk.getNFTFromBlacklist("22");
    console.log("Got NFTs from the black list:", nft_1_, nft_22_);
  });

  it("Handle User Black List:", async function () {
    await mgk.addUserToBlackList(owner.address);
    console.log("Add owner to the black list");

    const owner_ = await mgk.getUserFromBlacklist(owner.address);
    console.log("Got owner from the black list:", owner_.slice(0, 10));

    await mgk.addUserToBlackList(user1.address);
    console.log("Add user1 to the black list");

    const owner_2_ = await mgk.getUserFromBlacklist(owner.address);
    const user1_ = await mgk.getUserFromBlacklist(user1.address);
    console.log(
      "Got owner and user1 from the black list:",
      owner_2_.slice(0, 10),
      user1_.slice(0, 10)
    );

    await mgk.removeUserFromBlackList(owner.address);
    console.log("Remove owner from the black list");

    const owner_3_ = await mgk.getUserFromBlacklist(owner.address);
    const user1_2_ = await mgk.getUserFromBlacklist(user1.address);
    console.log(
      "Got owner and user1 from the black list:",
      owner_3_.slice(0, 10),
      user1_2_.slice(0, 10)
    );
  });

  // it("Get totalSupply:", async function () {
  //   const supply = await mgk.totalSupply();
  //   expect(supply).to.eq(5);
  //   console.log("supply:", supply.toNumber());
  // });

  it("Mint:", async function () {
    const mintOwnerTx = await mgk.safeMint(owner.address, 1);
    await mintOwnerTx.wait();

    const ownerTokens = await mgk.userTokens(owner.address);
    expect(ownerTokens[0].toNumber()).to.eq(1);
    console.log("ownerTokens:", ownerTokens[0].toNumber());

    // ---

    const mintUserTx = await mgk.safeMint(user1.address, 2);
    await mintUserTx.wait();

    const userTokens = await mgk.userTokens(owner.address);
    expect(userTokens[0].toNumber()).to.eq(1);
    console.log("userTokens:", userTokens[0].toNumber());

    // ---

    try {
      const mintUserAgainTx = await mgk.safeMint(user1.address, 3);
      await mintUserAgainTx.wait();
      expect(userTokensAgain[0].toNumber()).to.eq(false);
      console.log("userTokensAgain:", userTokensAgain[0].toNumber());
    } catch (err) {
      console.log("ERROR:", err.message);
    }
  });

  it("Get _owner and balance:", async function () {
    const _owner = await owner.getAddress();
    const balance = await owner.getBalance();

    expect(_owner.toString().length > 0).to.eq(true);
    expect(balance.toString().length > 0).to.eq(true);

    console.log("owner:", _owner);
    console.log("balance:", balance.toString());
  });

  it("Compare owner addresses:", async function () {
    const _owner = await mgk.owner();
    const owner_ = owner.address;
    expect(_owner).to.eq(owner_);
    console.log("_owner = owner_:", _owner.slice(0, 10), owner_.slice(0, 10));
  });

  it("contract.balanceOf:", async function () {
    console.log("contract:", await contract.balanceOf(owner.address));
  });

  it("Check mint event:", async function () {
    const mintTx = await mgk.safeMint(owner.address, 1);
    await mintTx.wait();

    await expect(mintTx)
      .to.emit(mgk, "Transfer")
      .withArgs("0x0000000000000000000000000000000000000000", owner.address, 1);

    console.log("event checking is successful!");
  });

  it("Owner and User mint:", async function () {
    const mintOwnerTx = await contract
      .connect(owner)
      .safeMint(owner.address, 1);
    await mintOwnerTx.wait();

    const ownerTokens = await contract.connect(owner).userTokens(owner.address);
    expect(ownerTokens[0].toNumber()).to.eq(1);
    console.log("ownerTokens:", ownerTokens[0].toNumber());

    // ---

    try {
      const mintUser1Tx = await contract
        .connect(user1)
        .safeMint(user1.address, 1);
      await mintUser1Tx.wait();

      const user1Tokens = await contract
        .connect(user1)
        .userTokens(user1.address);
      expect(user1Tokens[0].toNumber()).to.eq(1);
      console.log("user1Tokens:", user1Tokens[0].toNumber());
    } catch (err) {
      console.log("ERROR mintUser1Tx");
    }
  });

  it("Set role for owner:", async function () {
    const role = 1;
    const response = await contract.connect(owner).setRole(owner.address, role);
    await response.wait();
    console.log("tx response:", Number(response.data.slice(-1)));
  });

  it("Set role for owner and user:", async function () {
    const role = 1;

    await contract.connect(owner).setRole(owner.address, role);
    console.log("1. owner set role 1 for owner:");
    const supply = await contract.connect(owner).totalSupply();
    console.log("1. owner see the totalSupply:", supply);

    try {
      await contract.connect(user1).setRole(user1.address, role);
      console.log("2. user1 set role 1 for user1:");
    } catch (err) {
      console.log("2. ERROR: user1 cen't set totalSupply");
    }

    try {
      const supply = await contract.connect(user1).totalSupply();
      console.log("3. user1 see the totalSupply:", supply);
    } catch (err) {
      console.log("3. ERROR in ..owner).setRole(user1..");
    }

    try {
      await contract.connect(owner).setRole(user1.address, role);
      console.log("4.1. owner set role 1 for user1:");
      const supply = await contract.connect(user1).totalSupply();
      console.log("4.2. user1 see the totalSupply:", supply);
    } catch (err) {
      console.log("4. ERROR in ..owner).setRole(user1..");
    }
  });

  // it("Get additional contract:", async function () {
  //   // const res = await contract.getAdditionalContracts(owner.address);
  //   console.log("res", await contract.getAdditionalContracts(owner.address));
  //   // console.log("res", res);
  // });
});
// */
