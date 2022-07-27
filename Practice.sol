// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Practice {
    string public name = "KlayLion";
    string public symbol = "KL";

    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => string) public tokenURIs;
    mapping(address => uint256[]) private _ownedTokens; // 소유한 토큰 리스트

    // Mint token : save owner and uri by token id
    function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory tokenURI
    ) public returns (bool) {
        // give an owner to tokens
        // save uri in the token
        tokenOwner[tokenId] = to;
        tokenURIs[tokenId] = tokenURI;

        // add token to the owner's list
        _ownedTokens[to].push(tokenId);

        return true;
    }

    // Remove token from owner's token list
    function _removeTokenFromList(address from, uint256 tokenId) private {
        // [10, 15, 19, 20] -> [10, 15, 20, 19] -> [10, 15, 20]
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        if (
            _ownedTokens[from].length != 1 &&
            tokenId != _ownedTokens[from][lastTokenIndex]
        ) {
            for (uint256 i = 0; i < _ownedTokens[from].length; i++) {
                if (tokenId == _ownedTokens[from][i]) {
                    // Swap last token with deleting token
                    _ownedTokens[from][i] = _ownedTokens[from][lastTokenIndex];
                    _ownedTokens[from][lastTokenIndex] = tokenId;
                    break;
                }
            }
        }
        _ownedTokens[from].pop();
    }

    // Change owner (from -> to)
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(from == msg.sender, "from != msg.sender");
        require(
            from == tokenOwner[tokenId],
            "you are not the owner of the token."
        );

        // delete my token and push token to another owner
        _removeTokenFromList(from, tokenId);
        _ownedTokens[to].push(tokenId);

        // save this token to new owner's list
        tokenOwner[tokenId] = to;
    }

    // Show owned Tokens
    function ownedTokens(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    // Set token uri
    function setTokenUri(uint256 id, string memory uri) public {
        tokenURIs[id] = uri;
    }
}
