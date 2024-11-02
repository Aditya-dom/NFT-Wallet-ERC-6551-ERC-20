// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract USDT is ERC20, ERC20Burnable, Ownable {

  using SafeERC20 for ERC20;

  constructor(address initialOwner) Ownable(initialOwner) ERC20("Tether USD", "USDT") {
    initialOwner = address(msg.sender);
  }
  
  function mint(uint256 amount) external onlyOwner {
    _mint(msg.sender, amount);
  }

}
