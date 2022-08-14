pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract NFTSimple {
    using Counters for Counters.Counter;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    string public name = "KlayLion";
    string public symbol = "KL";

    // onKIP17Received bytes value
    bytes4 private constant _KIP17_RECEIVED =
        bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"));

    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => string) public tokenURIs;
    mapping(address => uint256[]) private _ownedTokens; // 소유한 토큰 리스트

    mapping(uint256 => address) private _tokenOwner;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => Counters.Counter) private _ownedTokensCount;

    // Show owned Tokens
    function ownedTokens(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    // Set token uri
    function setTokenUri(uint256 id, string memory uri) public {
        tokenURIs[id] = uri;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "KIP17: balance query for the zero address"
        );

        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(
            owner != address(0),
            "KIP17: owner query for nonexistent token"
        );

        return owner;
    }

    // Change owner (from -> to)
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
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

        // 받는 쪽이 실행할 코드가 있는 스마트 컨트렉트라면 코드를 실행할 것
        require(
            _checkOnKIP17Received(from, to, tokenId, _data),
            "KIP17: transfer to non KIP17Receiver implementer"
        );
    }

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

    function burn(address owner, uint256 tokenId) public {
        require(
            ownerOf(tokenId) == owner,
            "KIP17: burn of token that is not own"
        );

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
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

    // Check block has code
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // Check data is KIP17
    function _checkOnKIP17Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bool success;
        bytes memory returndata;

        if (!isContract(to)) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _KIP17_RECEIVED,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );

        if (
            returndata.length != 0 &&
            abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED
        ) {
            return true;
        }

        return false;
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract NFTMarket {
    mapping(uint256 => address) public seller;

    // Buy NFT
    function buyNFT(address NFTAddress, uint256 tokenId)
        public
        payable
        returns (bool)
    {
        // set seller "KLAY-receivable" form
        address payable receiver = address(uint160(seller[tokenId]));

        // send 0.01 KLAY : 10**16 PED = 0.01 KLAY
        receiver.transfer(10**16);

        NFTSimple(NFTAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            "0x00"
        );
        return true;
    }

    // Record seller : on token received
    function onKIP17Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        seller[tokenId] = from;
        return
            bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"));
    }
}
