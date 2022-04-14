// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;

import "./Collection.sol";
import "./YangMoyToken.sol";

contract YangFarm is Ownable, IERC721Receiver {

  uint256 public totalStake;

  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  event NFTStaked(address owner, uint256 tokenId, uint256 value);
  event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  Collection nft;
  YangMoyToken token;

  mapping(uint256 => Stake) public vault;

  constructor(Collection _nft, YangMoyToken _token){
    nft = _nft;
    token = _token;
  }

  function stake(uint256[] calldata _tokenIds) external {
    uint256 tokenId;
    totalStake += _tokenIds.length;
    for(uint i = 0; i < _tokenIds.length; i++){
      tokenId = _tokenIds[i];
      require(nft.ownerOf(tokenId) == msg.sender, "not your token");
      require(vault[tokenId].tokenId == 0, "already staked");

      nft.transferFrom(msg.sender, address(this), tokenId);
      emit NFTStaked(msg.sender, tokenId, block.timestamp);

      vault[tokenId] = Stake(uint24(tokenId), uint48(block.timestamp), msg.sender);
    }
  }

  function _unstakeMany(address _account, uint256[] calldata _tokenIds) internal {
    uint256 tokenId;
    totalStake += _tokenIds.length;
    for(uint i = 0; i < _tokenIds.length; i++){
      tokenId = _tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "not an owner");

      delete vault[tokenId];
      emit NFTUnstaked(msg.sender, tokenId, block.timestamp);

      nft.transferFrom(address(this), _account, tokenId);
    }
  }

  function _claim(address _account, uint256[] calldata _tokenIds, bool _unstake) internal {
    uint256 tokenId;
    uint256 earned = 0;

    for(uint i = 0; i < _tokenIds.length; i++){
      tokenId = _tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == _account, "not an owner");
      uint256 stakedAt = staked.timestamp;
      earned += 100000 ether * (block.timestamp - stakedAt) / 1 days;
      vault[tokenId] = Stake(uint24(tokenId), uint48(block.timestamp), _account);
    }

    if(earned > 0){
      earned = earned / 10000;
      token.mint(_account, earned);
    }
    if(_unstake){
      _unstakeMany(_account, _tokenIds);
    }
    emit Claimed(_account, earned);
  }

  function earningInfo(uint256 _tokenId) external view returns (uint256[1] memory info) {
    uint256 earned = 0;
    Stake memory staked = vault[_tokenId];
    uint256 stakedAt = staked.timestamp;
    earned += 100000 ether * (block.timestamp - stakedAt) / 1 days;
    return [earned];
  }

  function balanceOf(address _account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply = nft.totalSupply();
    for(uint i = 0; i <= supply; i++){
      if(vault[i].owner == _account){
        balance += 1;
      }
    }
    return balance;
  }

  function tokensOfOwner(address _account) public view returns (uint256[] memory ownerTokens) {
    uint256 supply = nft.totalSupply();
    uint256 [] memory tmp = new uint256[](supply);

    uint256 index = 0;
    for(uint tokenId = 1; tokenId <= supply; tokenId++){
      if(vault[tokenId].owner == _account){
        tmp[index] = vault[tokenId].tokenId;
        index += 1;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++){
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
    require(from == address(0x0), "Cannot send nfts to Vault directly");
    return IERC721Receiver.onERC721Received.selector;
  }
}