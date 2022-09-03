// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KryptoToy is ERC721 {

    struct Auction {
        uint256 startTime;
        uint256 timeStep;
        uint256 startPrice;
        uint256 endPrice;
        uint256 priceStep;
        uint256 stepNumber;
    }

    struct Voucher {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    address private _owner;

    Auction public auction;

    address[] public whitelistArray;
    mapping(address => bool) public whitelistMapping;

    modifier onlyOwner {
        require(msg.sender == _owner, "not owner");
        _;
    }

    bytes32 merkleRoot;

    address _signer = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    constructor(address[] memory whitelist, bytes32 _root) ERC721("KryptoToy", "KT") {
        _owner = msg.sender;
        merkleRoot = _root;

        for (uint256 i; i < whitelist.length; i++) {
            whitelistArray.push(whitelist[i]);
            whitelistMapping[whitelist[i]] = true;
        }
    }

    function inWhitelistArray() private view returns (bool) {
        for (uint256 i; i < whitelistArray.length; i++) {
            if (whitelistArray[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function whitelistMintFromArray() external {
        require(inWhitelistArray(), "not in whitelist");
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        _tokenIds.increment();
    }

    function whitelistMintFromMapping() external {
        require(whitelistMapping[msg.sender], "not in whitelist");
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        _tokenIds.increment();
    }

    // "50000000000000000" -> 0.05 ether
    function getAuctionPrice() public view returns (uint256) {
        Auction memory currentAuction = auction;
        if (block.timestamp < currentAuction.startTime) {
            return currentAuction.startPrice;
        }
        uint256 step = (block.timestamp - currentAuction.startTime) /
            currentAuction.timeStep;
        if (step > currentAuction.stepNumber) {
            step = currentAuction.stepNumber;
        }
        return
            currentAuction.startPrice > step * currentAuction.priceStep
                ? currentAuction.startPrice - step * currentAuction.priceStep
                : currentAuction.endPrice;
    }

    function setAuction(
        uint256 _startTime,
        uint256 _timeStep,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _priceStep,
        uint256 _stepNumber
    ) public onlyOwner {
        auction.startTime = _startTime; // 開始時間
        auction.timeStep = _timeStep; // 5 多久扣一次
        auction.startPrice = _startPrice; // 50000000000000000 起始金額
        auction.endPrice = _endPrice; // 10000000000000000 最後金額
        auction.priceStep = _priceStep; // 10000000000000000 每次扣除多少金額
        auction.stepNumber = _stepNumber; // 5 幾個階段
    }

    function auctionMint() external payable {
        require(msg.value >= getAuctionPrice(), "not enough value");
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        _tokenIds.increment();
    }

    function publicMint(uint256 _amount) external {
        for (uint256 i; i < _amount; i++) {
            uint256 tokenId = _tokenIds.current();
            _mint(msg.sender, tokenId);
            _tokenIds.increment();
        }
    }

    function ownerMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIds.current();
        _mint(to, tokenId);

        _tokenIds.increment();
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

    function whitelistMintFromMerkleProof(
        bytes32[] memory _proof
    ) external {
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "not in merkle proof whitelist");
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        _tokenIds.increment();
    }

    function signatureMint(
        uint256 tokenId,
        Voucher memory voucher
    ) public {
        bytes32 digest = keccak256(abi.encode(msg.sender, tokenId));

        require(_isVerifiedVoucher(digest, voucher), "signature failed..");

        _mint(msg.sender, tokenId);
    }

    function _isVerifiedVoucher(bytes32 digest, Voucher memory voucher) internal view returns (bool) {
        address signer = ecrecover(digest, voucher.v, voucher.r, voucher.s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer == _signer;
    }
}