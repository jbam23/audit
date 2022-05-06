const { expect } = require('chai');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const { network, ethers } = require("hardhat");
const { parse } = require('path');


describe('Honeyfrens NFT Tests', () => {
    let leafNodes,merkleTree,rootHash,leaf,hexProof;
    beforeEach(async () => {
        [whitelist1,whitelist2,whitelist3,whitelist4,whitelist5,whitelist6,airdropee1,airdropee2,unverifiedMinter] = await ethers.getSigners();
        honeyFrensJamesFactory = await ethers.getContractFactory('HoneyFrensJames');
        honeyFrensFactory = await ethers.getContractFactory('HONEYFRENS');

        // exploitFactory = await ethers.getContractFactory('ExploitSim');

        let whitelist = [
            whitelist1.address,
            whitelist2.address,
            whitelist3.address,
            whitelist4.address,
            whitelist5.address,
            whitelist6.address
        ]
        
        leafNodes = whitelist.map(item => keccak256(item))
        merkleTree = new MerkleTree(leafNodes, keccak256, {sortPairs: true});
        rootHash = merkleTree.getRoot();
        leaf = leafNodes[0]
        hexProof = merkleTree.getHexProof(leaf)
    
        honeyFrensJames = await honeyFrensJamesFactory.deploy();
        honeyFrens = await honeyFrensFactory.deploy();

        console.log("Root = " + rootHash.toString('hex'))
        console.log("Proof = " + hexProof)
        // console.log("Whitelist Merkle Tree \n", merkleTree.toString());
        console.log("HoneyFrensJames Contract Deployed to: "+ honeyFrensJames.address)
        console.log("HoneyFrens Contract Deployed to: "+ honeyFrens.address)

    });


    it('Honeyfrens Test Whitelist and Public Mint:', async () => {
        await honeyFrensJames.setMerkleRoot("0x8ae4777407987470bb4c7cde049e112c915237cb4c3c248b605355ddbac307a3")
        await honeyFrens.setMerkleRoot("0x8ae4777407987470bb4c7cde049e112c915237cb4c3c248b605355ddbac307a3")

        // Start Whitelist and Public Mint
        await honeyFrensJames.toggleSale()
        await honeyFrens.toggleSale()

        await honeyFrensJames.togglePreSale()
        await honeyFrens.togglePreSale()

        //  Test Whitelist Mint
        // Get proof for whitelist address 1
        var hexProof1 = merkleTree.getHexProof(keccak256(whitelist1.address))
        await honeyFrensJames.connect(whitelist1).presaleMintItems(2,hexProof1,{value: ethers.utils.parseEther('0.6')})
        await honeyFrens.connect(whitelist1).presaleMintItems(2,hexProof1,{value: ethers.utils.parseEther('0.6')})

        // Test Public Mint
        await honeyFrensJames.mintItems(5,{value: ethers.utils.parseEther('1.5')})
        await honeyFrens.mintItems(5,{value: ethers.utils.parseEther('1.5')})

        // Test Airdrop
        var aidrops = [airdropee1.address,airdropee2.address]
        await honeyFrensJames.airdrop(aidrops)

        var bal1 = await honeyFrensJames.balanceOf(airdropee1.address)
        var bal2 = await honeyFrensJames.balanceOf(airdropee2.address)

        expect(parseInt(bal1._hex)).to.equal(1)
        expect(parseInt(bal2._hex)).to.equal(1)

        // Test Withdraw
        await honeyFrensJames.withdraw();


    });

});