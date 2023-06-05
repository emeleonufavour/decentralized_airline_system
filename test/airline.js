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
                            "Owner is an admin", async function(){
                                const {owner, airlineToken} = await loadFixture(deployTokenFixture);
                                expect(await airlineToken.isAdmin(owner.address)).to.be.true;
                                }
                            );
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
                        it(
                            "Owner and admin can set the seat price", async function(){
                                const {airlineToken, addr1} = await loadFixture(deployTokenFixture);
                                await airlineToken.addAdmin(addr1.address);
                                expect(await airlineToken.setSeatPrice(100)).to.not.be.reverted;
                            }
                        ); 
                        // it(
                        //     "Only someone with a ticket can transfer seats", async function(){
                        //         const {owner, airlineToken, addr1} = await loadFixture(deployTokenFixture);
                        //         await airlineToken.transferSeat(addr1.address);
                        //         expect(await airlineToken.setSeatPrice(100)).to.not.be.reverted;
                        //     }
                        // );
                    }
                );
                describe("Customer actions", async function(){
                    it(
                        "Able to book one seat in the flight", async function(){
                            const {airlineToken} = await loadFixture(deployTokenFixture);
                            await airlineToken.bookOneSeat();
                            expect(await airlineToken._seatPurchaseIndex()).to.not.equal(0);
                        }
                    );
                    it(
                        "Able to book more than one seat in the flight", async function(){
                            const {owner,airlineToken, } = await loadFixture(deployTokenFixture);
                            await airlineToken.bookOneSeat();
                            await airlineToken.bookOneSeat();
                            await airlineToken.bookOneSeat();
                            const length = await airlineToken._ownerSeats(airlineToken._owner()).length;
                            console.log(`This is the length: ${length}`);//I have an error 
                            expect(await airlineToken._seatPurchaseIndex()).to.equal(3);//getting the length of a member of the map
                            expect(length).to.not.equal(0);
                        }
                    );
                });
                
                it(
                    "Able to set seat price", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        await airlineToken.setSeatPrice(1);
                        const contractSeatPrice = await airlineToken._seatPrice();
                        expect(contractSeatPrice).to.equal(1);
                    }
                );
                it(
                    "Able to set the amount of vacant seats left", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        await airlineToken. setVacantSeats(1);
                        const contractVacantSeats = await airlineToken._seatsRemaining();
                        expect(contractVacantSeats).to.equal(1);
                    }
                );
                it(
                    "Able to set the amount of seats", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        await airlineToken.setSeatCount(1);
                        const contractSeats = await airlineToken._seatCount();
                        expect(contractSeats).to.equal(1);
                    }
                );
                it(
                    "Able to approve flights", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        await airlineToken.setSeatCount(1); 
                        expect(await airlineToken.approveFlight()).to.not.be.reverted;
                    }
                );
                it(
                    "Able to close flights", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        await airlineToken.setSeatCount(1); 
                        await airlineToken.approveFlight();
                        expect(await airlineToken.closeFlight()).to.not.be.reverted;
                    }
                );
                it(
                    "Able to land flights", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        await airlineToken.setSeatCount(1); 
                        await airlineToken.approveFlight();
                        expect(await airlineToken.landFlight()).to.not.be.reverted;
                    }
                );
                it(
                    "Able to finalise flights", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        await airlineToken.setSeatCount(1); 
                        await airlineToken.approveFlight();
                        expect(await airlineToken.finalizeFlight()).to.not.be.reverted;
                    }
                );
                it(
                    "Able to cancel flights", async function(){
                        const {airlineToken} = await loadFixture(deployTokenFixture);
                        await airlineToken.setSeatCount(1); 
                        await airlineToken.approveFlight();
                        expect(await airlineToken.cancelFlight()).to.not.be.reverted;
                    }
                );
            }
        );
    }
);