//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

interface YFMI_DID {
    
    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        /// @notice The metadata URI to associate with this token.
        string uri;
        /// @notice The metadata URI to associate with this token.
        string username;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    /// @notice Returns the name of the contract
    function getName() view external returns (string memory);

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(address redeemer, NFTVoucher calldata voucher) external payable returns (uint256);

    /// @notice Sets the Metadata URI of the NFY
    /// @param tokenId The ID of the NFT
    /// @param uri The uri of the metafile, typically in IPFS
    function setTokenURI(uint256 tokenId, string memory uri) external;

    /// @notice Gets the username 
    /// @param tokenId The ID of the NFT
    function getUsername(uint256 tokenId) view  external returns (string memory);

    /// @notice Gets the TokenID by Username
    /// @param username The username
    function getTokenByUsername(string memory username)  view  external returns (uint256);

    /// @notice Gets the TokenID by DID
    /// @param did The username
    function getTokenByDid(string calldata did) view  external returns (uint256);

    /// @notice Gets the Did by Username
    /// @param username The username
    function getDidByUsername(string calldata username)  view external returns (string memory);

    /// @notice Gets the Username by DID
    /// @param did The DID
    function getUsernameByDid(string memory did) view external returns (string memory);

    /// @notice Checks if a signature is valid
    /// @param signer The Address of the signer
    /// @param hash The hash if the message
    /// @param signature The signature
    function isValidSignature(address signer, bytes32 hash, bytes calldata signature) view external returns (bytes4);
}