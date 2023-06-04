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
                describe(
                    "Administrative priviledges", async function(){
                      it(
                    "Owner can change regulators", async function(){
                        const {airlineToken, addr1} = await loadFixture(deployTokenFixture);
                        expect(await airlineToken.changeRegulator(addr1.address)).
                        to.not.be.revertedWith("Only the owner");
                        }
                      ); 
                      it(
                        "Owner can add admin", async function(){
                            const {airlineToken, addr1} = await loadFixture(deployTokenFixture);
                            expect(await airlineToken.addAdmin(addr1.address)).
                            to.not.be.revertedWith("Only the owner");
                            }
                        ); 
                        it(
                            "Owner can remove admin", async function(){
                                const {airlineToken, addr1} = await loadFixture(deployTokenFixture);
                                await airlineToken.addAdmin(addr1.address);
                                expect(await airlineToken.removeAdmin(addr1.address)).
                                to.not.be.revertedWith("Only the owner");
                            }
                        ); 
                        it(
                            "Account is an admin", async function(){
                                const {airlineToken, addr1} = await loadFixture(deployTokenFixture);
                                await airlineToken.addAdmin(addr1.address);
                                const adminStatus = await airlineToken.isAdmin(addr1.address);
                                expect(adminStatus).to.be.true;
                            }
                        ); 
                        it(
                            "Account is the regulator", async function(){
                                const {airlineToken, addr1} = await loadFixture(deployTokenFixture);
                                await airlineToken.changeRegulator(
                                    addr1.address
                                );
                                const regulatorStatus = await airlineToken.isRegulator(addr1.address);
                                expect(regulatorStatus).to.be.true;
                            }
                        ); 
                    }
                );
                
                it(
                    "Able to set seat price", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        expect(await airlineToken.setSeatPrice(1000)).
                        to.not.be.revertedWith("Only the owner");
                    }
                );
                it(
                    "", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        expect(await airlineToken.setSeatPrice(1000)).
                        to.not.be.revertedWith("Only the owner");
                    }
                );
            }
        );
    }
);