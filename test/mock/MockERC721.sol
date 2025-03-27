// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";


contract MockERC721 is ERC721{
    uint256 private _tokenId;

    constructor() ERC721("Test", "tt"){}
    

    function mint(address to, uint256 tokenId) public returns (uint256) {
        _tokenId = tokenId;
        _safeMint(to, tokenId);
        return tokenId;
    }
}