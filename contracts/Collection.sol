// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Collection is ERC721Enumerable, ERC721URIStorage, Ownable{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenId;
  uint256 public maxSupply = 1000;

  event Mint(address indexed minter, uint256 tokenId);

  constructor() ERC721("Yang DDi Club", "YDC") {}

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal
    override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(
    uint256 tokenId
  ) internal
    override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(
    uint256 tokenId
  ) public view
    override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function mint(string memory _tokenUri) external returns(uint256){
    uint256 currentSupply = totalSupply();
    require(currentSupply < maxSupply, "Cannot mint anymore...");
    _tokenId.increment();

    uint256 currentTokenId = _tokenId.current();
    _safeMint(msg.sender, currentTokenId, "");
    _setTokenURI(currentTokenId, _tokenUri);

    return currentTokenId;
  }

  function getTotalMinted() external view returns(uint256) {
    return _tokenId.current();
  }

  function setMaxSupply(uint256 _newSupply) external onlyOwner {
    maxSupply = _newSupply;
  }
}