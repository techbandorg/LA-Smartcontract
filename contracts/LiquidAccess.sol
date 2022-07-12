// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract LiquidAccess is
  Context,
  ERC165,
  AccessControl,
  IERC721,
  IERC721Metadata,
  Ownable
{
  struct TokenMetaData {
    string URI;
  }

  // Roles:
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
  bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

  using Address for address;
  using Strings for uint256;

  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.UintSet;

  Counters.Counter private _tokenIdCounter;
  // AdditionalContract1 public _additionalContract1;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Token baseURI
  string private _baseURI;

  // Token Total Supply
  uint256 private _totalSupply;

  // Merchant name
  string private _merchantName;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from token Id to uri
  mapping(uint256 => string) private uris;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  mapping(uint256 => TokenMetaData) private _tokenMetaDatas;
  mapping(address => EnumerableSet.UintSet) private _holderTokens;

  // Black list (user)
  mapping(address => address) private userBlackList;

  // Black list (nft)
  mapping(uint256 => uint256) private nftBlackList;

  event SetBaseURI(string indexed baseURI);

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    string memory merchantName_
  ) {
    _name = name_;
    _symbol = symbol_;
    _totalSupply = totalSupply_;
    _tokenIdCounter.increment();
    _baseURI = 'ipfs://';
    _merchantName = merchantName_;
    // _additionalContract1 = AdditionalContract1(msg.sender);
    // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  // function getAdditionalContracts(address owner)
  //     public
  //     view
  //     returns (address addr)
  // {
  //     addr = _additionalContract1.connection1(owner);
  //     return addr;
  // }

  function setRole(address account, uint256 role)
    public
    onlyOwner
    returns (address)
  {
    require(account != address(0), 'zero address!');

    if (role == 1) {
      _setupRole(ADMIN_ROLE, account);
    } else if (role == 2) {
      _setupRole(MANAGER_ROLE, account);
    }

    return account;
  }

  // NFT Black List
  function getNFTFromBlacklist(uint256 _nft) public view returns (uint256) {
    return nftBlackList[_nft];
  }

  function addNFTToBlackList(uint256 _nft) public returns (uint256) {
    nftBlackList[_nft] = _nft;
    return nftBlackList[_nft];
  }

  function removeNFTFromBlackList(uint256 _nft) public returns (string memory) {
    delete nftBlackList[_nft];
    return 'removed';
  }

  // User Black List
  function getUserFromBlacklist(address _user) public view returns (address) {
    return userBlackList[_user];
  }

  function addUserToBlackList(address _user) public returns (address) {
    userBlackList[_user] = _user;
    return userBlackList[_user];
  }

  function removeUserFromBlackList(address _user)
    public
    returns (string memory)
  {
    delete userBlackList[_user];
    return 'removed';
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165, AccessControl)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function userTokens(address owner)
    external
    view
    virtual
    returns (uint256[] memory)
  {
    require(owner != address(0), 'zero address (balance query)');

    uint256[] memory result = new uint256[](_holderTokens[owner].length());

    for (uint256 i; i < _holderTokens[owner].length(); i++) {
      result[i] = _holderTokens[owner].at(i);
    }
    return result;
  }

  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), 'zero address (invalid owner)');
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = _owners[tokenId];
    require(owner != address(0), 'nonexistent token (owner query)');
    return owner;
  }

  // onlyRole(MANAGER_ROLE)
  function name()
    public
    view
    virtual
    override
    onlyRole(MANAGER_ROLE)
    returns (string memory)
  {
    return _name;
  }

  // onlyRole(ADMIN_ROLE)
  function symbol()
    public
    view
    virtual
    override
    onlyRole(ADMIN_ROLE)
    returns (string memory)
  {
    return _symbol;
  }

  function merchantName() public view returns (string memory) {
    return _merchantName;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'nonexistent token (URI query)');

    string memory _tokenURI = uris[tokenId];
    string memory base = baseURI();

    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    return string(abi.encodePacked(base, tokenId.toString()));
  }

  function baseURI() public view virtual returns (string memory) {
    return _baseURI;
  }

  function setBaseURI(string memory baseURI_) external virtual onlyOwner {
    _baseURI = baseURI_;
    emit SetBaseURI(baseURI_);
  }

  function approve(address to, uint256 tokenId) public virtual override {
    address owner = LiquidAccess.ownerOf(tokenId);
    require(to != owner, 'approval to current owner');

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      'caller is not owner'
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), 'nonexistent token (appr. query)');

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'is not owner nor approved'
    );

    require(
      getNFTFromBlacklist(tokenId) != tokenId,
      'NFT is in the Black List'
    );
    require(
      getUserFromBlacklist(from) != from,
      'User (from) is in the Black List'
    );
    require(getUserFromBlacklist(to) != to, 'User (to) is in the Black List');

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'not owner nor approved'
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      'non ERC721Receiver implementer'
    );
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), 'nonexistent token (oper. query)');
    address owner = LiquidAccess.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  // function userTokens(address owner) external view virtual returns (uint[] memory) {
  //     require(owner != address(0), "Balance query for the zero address");

  //     uint[] memory result = new uint[](_holderTokens[owner].length());

  //     for (uint i; i < _holderTokens[owner].length(); i++) {
  //         result[i] = _holderTokens[owner].at(i);
  //     }
  //     return result;
  // }

  function safeMint(address to, string memory uri) public onlyOwner {
    require(_balances[to] == 0, 'You may have one NFT');
    _safeMint(to, _tokenIdCounter.current(), uri, '');
    _tokenIdCounter.increment();
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    string memory uri,
    bytes memory _data
  ) internal {
    uris[tokenId] = uri;
    _mintTo(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      'non ERC721Receiver implementer'
    );
  }

  function _mintTo(address to, uint256 tokenId) internal virtual {
    require(msg.sender != address(0), 'Can mint only owner');

    _balances[to] += 1;
    _owners[tokenId] = to;
    _holderTokens[to].add(tokenId);

    emit Transfer(address(0), to, tokenId);
  }

  function updateURI(uint256 tokenId, string memory uri) public onlyOwner {
    uris[tokenId] = uri;
  }

  function updateUriBatch(uint256[] memory tokenId, string[] memory uri)
    public
    onlyOwner
  {
    for (uint256 i; i < tokenId.length; i++) {
      uris[tokenId[i]] = uri[i];
    }
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      LiquidAccess.ownerOf(tokenId) == from,
      'transfer from incorrect owner'
    );
    require(to != address(0), 'transfer to the zero address');

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;
    _holderTokens[from].remove(tokenId);
    _holderTokens[to].add(tokenId);

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(LiquidAccess.ownerOf(tokenId), to, tokenId);
  }

  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, 'Approve to caller');
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert('non ERC721Receiver implementer');
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }
}

// abstract contract AdditionalContract1 {
//     function connection1(address _owner) public pure returns (address) {
//         return _owner;
//     }
// }

// contract AdditionalContract2 {
//     function connection2() internal pure returns (string memory) {
//         return "Additional contract 2";
//     }
// }
