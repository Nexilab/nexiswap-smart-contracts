// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import {IPancakeProfile} from "./interfaces/IPancakeProfile.sol";
import "./BunnyMintingStation.sol";

contract BunnySpecialXmas is Ownable {
    BunnyMintingStation public immutable bunnyMintingStation;
    INexiSwapProfile public immutable nexiSwapProfile;

    uint256 public endBlock; // End of the distribution

    // NexiSwap Profile points threshold
    uint256 public nexiSwapProfileThresholdPoints;

    uint8 public immutable nftId; // Nft can be minted
    string public tokenURI; // Nft token URI

    mapping(address => bool) public hasClaimed;

    event BunnyMint(address indexed to, uint256 indexed tokenId, uint8 indexed bunnyId);
    event NewEndBlock(uint256 endBlock);
    event NewPancakeProfileThresholdPoints(uint256 thresholdPoints);
    event NewTokenURI(string tokenURI);

    /**
     * @notice It initializes the contract.
     * @param _bunnyMintingStationAddress: BunnyMintingStation address
     * @param _nexiSwapProfileAddress: PancakeProfile address
     * @param _nexiSwapProfileThresholdPoints: User points threshold for mint NFT
     * @param _nftId: Nft can be minted
     * @param _endBlock: the end of the block
     */
    constructor(
        address _bunnyMintingStationAddress,
        address _nexiSwapProfileAddress,
        uint256 _nexiSwapProfileThresholdPoints,
        uint8 _nftId,
        uint256 _endBlock
    ) public {
        bunnyMintingStation = BunnyMintingStation(_bunnyMintingStationAddress);
        nexiSwapProfile = IPancakeProfile(_nexiSwapProfileAddress);
        nexiSwapProfileThresholdPoints = _nexiSwapProfileThresholdPoints;
        nftId = _nftId;
        endBlock = _endBlock;
    }

    /**
     * @notice Update end block for distribution
     * @dev Only callable by owner.
     */
    function updateEndBlock(uint256 _newEndBlock) external onlyOwner {
        endBlock = _newEndBlock;
        emit NewEndBlock(_newEndBlock);
    }

    /**
     * @notice Update thresholdPoints for distribution
     * @dev Only callable by owner.
     */
    function updateThresholdPoints(uint256 _newThresholdPoints) external onlyOwner {
        nexiSwapProfileThresholdPoints = _newThresholdPoints;
        emit NewPancakeProfileThresholdPoints(_newThresholdPoints);
    }

    /**
     * @notice Update tokenURI for distribution
     * @dev Only callable by owner.
     */
    function updateTokenURI(string memory _newTokenURI) external onlyOwner {
        tokenURI = _newTokenURI;
        emit NewTokenURI(_newTokenURI);
    }

    /**
     * @notice Mint a NFT from the BunnyMintingStation contract.
     * @dev Users can claim once. It maps to the teamId.
     */
    function mintNFT() external {
        require(canClaim(msg.sender), "User: Not eligible");
        hasClaimed[msg.sender] = true;
        // Mint collectible and send it to the user.
        uint256 tokenId = bunnyMintingStation.mintCollectible(msg.sender, tokenURI, nftId);
        emit BunnyMint(msg.sender, tokenId, nftId);
    }

    /**
     * @notice Check if user can claim NFT.
     */
    function canClaim(address _userAddress) public view returns (bool) {
        (, uint256 numberUserPoints, , , , bool active) = nexiSwapProfile.getUserProfile(_userAddress);
        // If user is able to mint this NFT
        if (
            !hasClaimed[_userAddress] &&
            block.number < endBlock &&
            active &&
            numberUserPoints >= nexiSwapProfileThresholdPoints
        ) {
            return true;
        }
        return false;
    }
}
