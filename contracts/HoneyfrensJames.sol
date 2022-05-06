
// Creator: HONEYFRENS
//Optimalization: 200

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import "erc721a/contracts/ERC721A.sol";

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract HoneyFrensJames is ERC721A, Ownable {
    using Strings for uint256;

    bool private _presaleActive = false;
    bool private _saleActive = false;
    string public _prefixURI;
    string public _baseExtension;

    uint256 public constant MAX_SUPPLY = 3000;
    //WEI 300000000000000000

    uint256 public  _price = 300000000000000000;    // 0.3 ETH
    uint256 private  _maxPresaleMint = 2;

    uint256 private  _maxTokens = 3000;

    uint256 private  _maxMint = 10;
    uint256 constant _maxMintAmountPerTx = 5;
    mapping (address => uint256) private _saleMints;

    address private constant sponsor = 0xaDefcC73aaF2f162FDc3354D750a6e424c758Df0;
    address private constant sponsor2 = 0xaDefcC73aaF2f162FDc3354D750a6e424c758Df0;
    address private constant withdrawAddress1 = 0xaDefcC73aaF2f162FDc3354D750a6e424c758Df0;
    uint256 private constant sponsorship = 2 ether;

    bytes32 private merkleRoot = 0x0;

    //string public uriPrefix = "https://";
    //string public uriSuffix = "";
    constructor() ERC721A("HONEYFRENS", "HONEYFRENS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier hasCorrectAmount(uint256 _wei, uint256 _quantity) {
        require(_wei >= _price * _quantity, "Insufficent funds");
        _;
    }

    /**
     * Public sale and whitelist sale mechansim
     */

    function airdrop(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _safeMint(addrs[i], 1);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function baseExtension() internal view returns (string memory) {
        return _baseExtension;
    }

    function setBaseExtension(string memory _ext) public onlyOwner {
        _baseExtension = _ext;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function preSaleActive() public view returns (bool) {
        return _presaleActive;
    }

    function saleActive() public view returns (bool) {
        return _saleActive;
    }

    function resetSaleMintsForAddrs(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _saleMints[addrs[i]] = 0;
        }
    }

    function togglePreSale() public onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
    }

    function updateMaxTokens(uint256 newMax) public onlyOwner {
        _maxTokens = newMax;
    }

    function updateMaxMint(uint256 newMax) public onlyOwner {
        _maxMint = newMax;
    }

    function updateMaxPresaleMint(uint256 newMax) public onlyOwner {
        _maxPresaleMint = newMax;
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721AMetadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        tokenId.toString();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), _baseExtension)) : "";
    }

    function mintItems(uint256 _quantity)
    public
    payable
    callerIsUser
    hasCorrectAmount(msg.value, _quantity)
    {
        require(_saleMints[msg.sender] + _quantity <= _maxMint, "Minting above public limit");
        require(_saleActive);
        require(totalSupply() + _quantity <= _maxTokens);
        require(_quantity <= _maxMintAmountPerTx);

        _saleMints[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function presaleMintItems(
        uint256 _quantity,
        bytes32[] calldata proof
    )
    external payable callerIsUser
    hasCorrectAmount(msg.value, _quantity)
    {
        uint64 newClaimTotal = _getAux(msg.sender) + uint64(_quantity); // Add users existing whitelist mint amount from _getAux to requested mint amout _quantity
        require(newClaimTotal <= _maxPresaleMint, "Exceeds mint amount per wallet!");
        require(_presaleActive);
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not whitelisted!");
        require(totalSupply() + _quantity <= _maxTokens);

        _setAux(msg.sender, newClaimTotal); // Set users new whitelist mint amount to newClaimTotal
        _safeMint(msg.sender, _quantity);
    }

    function withdraw() external onlyOwner {
        //todo addresses
        require(address(this).balance > 0);
        payable(withdrawAddress1).transfer(address(this).balance);
    }

    function withdrawSponsorship() external onlyOwner {
        require(address(this).balance >= sponsorship);
        payable(sponsor).transfer(sponsorship * 50 / 100);
        payable(sponsor2).transfer(sponsorship * 50 / 100);
    }
}
