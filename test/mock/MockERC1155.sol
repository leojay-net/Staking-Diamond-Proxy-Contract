// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";


contract MockERC1155 is ERC1155 {
    
    constructor() ERC1155("http://test.com/"){}

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
    {
        _mint(account, id, amount, data);
    }

}