# Audit
Notes:

-Unused variable maxMintAmountPerTx in Honeyfrens.sol

-Unused modifier withinMaximumSupply in Honeyfrens.sol

Made a few changes that reduced the overall gas used for minting. For example the gas cost for minting 2 from the whitelist mint went from 155k gas consumed to 112k gas consumed which saves about 27.6855% in gas. Some changes I made in the HoneyfrensJames.sol include:
1. Removing all the Counters stuff tracking tokenID's in the mint functions are its not needed and require checks can just check totalSupply() for total amount minted so far.
    - removed increaseTokenID function too, as not sure what you need it for - unless you are trying to skip around certain tokenID's for some reason?
2. Replaced _presaleMints mapping used in presaleMintItems with the getAux/setAux methods from the ERC721A contract (which saves about 15% gas - can see explanation here https://github.com/chiru-labs/ERC721A/issues/135)
3. Removed "require(msg.value >= _quantity * _price);" statement from _presaleMints because it is duplicate check as payment is already verified in hasCorrectAmount modifier

Within mintItems function there are 2 duplicate requires that check if  _saleMints[msg.sender] + _quantity <= _maxMint, so both are not needed. Were one of the duplicate checks in mintItems intended to be a check with the unused variable maxMintAmountPerTx  to limit the max allowed mint per transaction maybe? But both _maxMint and _maxMintAmountPerTx are both set to 5 it seems redundant as checking _maxMint<5 will catch all cases that _maxMintAmountPerTx<5 will.

Typically you only want to limit the amount an account can mint per transaction to something like 5, but let them submit any number of transactions up to that limit of 5. But if you want to limit each account to _maxMint amount for the public mint, which you can reset in your resetSaleMintsForAddrs method, then you should have it be something greater than _maxMintAmountPerTx. So in HoneyfrensJames.sol the 2 checks are (dont need to check greater than 0 as ERC721A internal mint function has a check for that, tested in line 62 of test/sim.js:

1. require(_saleMints[msg.sender] + _quantity <= _maxMint, "Minting above public limit");   //checks that the requested mint amount + users current public mint count is not greater than specified public mint max, something greater than _maxMintAmountPerTx
2. require(_quantity <= _maxMintAmountPerTx); //checks that the requested mint amount is less than the specified max per transaction, something like 5 

Not sure where you got that version of ERC721A but seems like its not the current version as its missing some functionality. I installed the current ERC721A straight from npm through 'npm install --save-dev erc721a' and then imported with 'import "erc721a/contracts/ERC721A.sol";' to get the newest version. For example the version you had did not have the getAux/setAux methods, but if you didnt want to use the getAux/setAux methods you can just use your current version of ERC721A and go back to your original implementation of tracking with the mapping _presaleMints instead of getAux/setAux.

Id also maybe recommend changing the updateMaxMint function to add in some kind of restriction so that you/the team cant change the total supply after a certain point so that the minters now there will only ever be a certain amount minted which is usually what people do. You can just add a bool like mintFinalized that you can flip to true, that wont allow the owner to change the total supply beyond that point and cant be flipped back to false.

Everything with the merkle root verification looks all correct

I added some tests into test/sim.js where I was checking the gas costs

Gas Consumption Tests:
Whitelist Mint 2 

New Version - 112376

Original Honeyfrens - 155399

