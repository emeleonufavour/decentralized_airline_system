const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");
const Web3 = require('web3');
const web3 = new Web3();

describe(
    "Airline contract", function(){
        async function deployTokenFixture(){
                        const [owner, addr1, addr2] = await ethers.getSigners();
                        const Airline = await ethers.getContractFactory("Airline");
                        const airlineToken = await Airline.deploy();

                        await airlineToken.deployed();
                        return {owner, addr1, addr2, airlineToken, Airline};
        }
        describe(
            "Deployment", async function(){
                it(
                    "Person who deployed the contract is the owner", async function(){
                        const {owner, airlineToken} = await loadFixture(deployTokenFixture);
                        expect(owner.address).to.equal(await airlineToken._owner());
                    }
                );
            }
        );
        describe(
            "Functions", async function(){
                it(
                    "Able to add regulators", async function(){
                        const {airlineToken, addr1} = await loadFixture(deployTokenFixture);
                        expect(await airlineToken.addRegulators(addr1.address)).
                        to.not.be.revertedWith("Only the owner");
                    }
                );
                it(
                    "Able to set seat price", async function(){
                        
                    }
                );
            }
        );
    }
);