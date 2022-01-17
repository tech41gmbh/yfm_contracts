//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

interface YoufoundmeDID {
    
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

contract YoufoundmeV0 is
    YoufoundmeDID,
    ERC721URIStorage,
    EIP712,
    AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant SIGNING_DOMAIN = "Youfoundme-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    mapping(address => uint256) pendingWithdrawals;
    mapping(uint256 => string) private _usernames;
    mapping(string => uint256) private _token_username;

    constructor(address payable minter)
        ERC721("Youfoundme", "YFM")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _setupRole(MINTER_ROLE, minter);
    }

    function getTokenByDid(string calldata did)
        public
        view
        override
        virtual
        returns (uint256 )
    {
        string memory sl = string(did[8:]);
        bytes32 b = keccak256(abi.encodePacked(sl));
        return uint256(b);
    }

    function getUsernameByDid(string calldata did)
        public
        view
        override
        virtual
        returns (string memory)
    {
        string memory sl = string(did[8:]);
        bytes32 b = keccak256(abi.encodePacked(sl));
        uint256 _tokenid = uint256(b);
        return _usernames[_tokenid];
    }

    function getDidByUsername(string memory username)
        public
        view
        override
        virtual
        returns (string memory)
    {
        uint256 _tokenId = _token_username[username];
        address a = ERC721.ownerOf(_tokenId);
        string memory ad = toAsciiString(a);
        return string(abi.encodePacked("yfm:did:0x", abi.encodePacked(ad)));
    }

    function redeem(address redeemer, NFTVoucher calldata voucher) override external 
        payable
        returns (uint256)
    {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        // make sure that the signer is authorized to mint NFTs
        require(
            hasRole(MINTER_ROLE, signer),
            "Signature invalid or unauthorized"
        );

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
        _setUsername(voucher.tokenId, voucher.username);

        // transfer the token to the redeemer
        _transfer(signer, redeemer, voucher.tokenId);

        // record payment to signer's withdrawal balance
        pendingWithdrawals[signer] += msg.value;

        return voucher.tokenId;
    }

    function setTokenURI(uint256 tokenId, string memory uri) override external {
        _setTokenURI(tokenId, uri);
    }

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
    function withdraw() public {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Only authorized minters can withdraw"
        );

        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(msg.sender);

        uint256 amount = pendingWithdrawals[receiver];
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[receiver] = 0;
        receiver.transfer(amount);
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.
    function availableToWithdraw() public view returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 tokenId,uint256 minPrice,string uri,string username)"
                        ),
                        voucher.tokenId,
                        voucher.minPrice,
                        keccak256(bytes(voucher.uri)),
                        keccak256(bytes(voucher.username))
                    )
                )
            );
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function getUsername(uint256 tokenId)
        public
        override
        view
        virtual
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: Username query for nonexistent token"
        );
        string memory _username = _usernames[tokenId];
        return _username;
    }

    function getTokenByUsername(string memory username)
        public
        override
        view
        virtual
        returns (uint256)
    {
        uint256 _tokenId = _token_username[username];
        return _tokenId;
    }

    // https://medium.com/metamask/eip712-is-coming-what-to-expect-and-how-to-use-it-bb92fd1a7a26
    function isValidSignature(
        address signer,
        bytes32 _hashv,
        bytes calldata _signature
    ) public view override virtual returns (bytes4) {
        // Validate signatures
        if (recoverSigner(_hashv, _signature) == signer) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }

/* ======================================================================================================
    Helper Functions 
    ======================================================================================================*/

    function getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes16 _HEX_SYMBOLS = "0123456789abcdef";
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function _setUsername(uint256 tokenId, string memory _username)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: Username set of nonexistent token"
        );
        _usernames[tokenId] = _username;
        _token_username[_username] = tokenId;
    }

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function hashToInteger(bytes32 x) internal pure  returns (uint256) {
        uint256 y;
        for (uint256 i = 0; i < 32; i++) {
            uint256 c = (uint256(x) >> (i * 8)) & 0xff;
            if (48 <= c && c <= 57) y += (c - 48) * 10**i;
            else if (65 <= c && c <= 90) y += (c - 65 + 10) * 10**i;
            else if (97 <= c && c <= 122) y += (c - 97 + 10) * 10**i;
            else break;
        }
        return y;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }

    function recoverSigner(bytes32 _hashv, bytes memory _signature)
        internal
        pure
        returns (address signer)
    {
        require(
            _signature.length == 65,
            "SignatureValidator#recoverSigner: invalid signature length"
        );

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        //
        // Source OpenZeppelin
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert(
                "SignatureValidator#recoverSigner: invalid signature 's' value"
            );
        }

        if (v != 27 && v != 28) {
            revert(
                "SignatureValidator#recoverSigner: invalid signature 'v' value"
            );
        }

        // Recover ECDSA signer
        signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hashv)
            ),
            v,
            r,
            s
        );

        // Prevent signer from being 0x0
        require(
            signer != address(0x0),
            "SignatureValidator#recoverSigner: INVALID_SIGNER"
        );
        return signer;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
}

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
