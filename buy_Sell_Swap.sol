// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

contract TokenMarketplace is Ownable {

    Token public token;
    uint256 public tokenPriceInWei;

    event BuyToken(address buyer, uint256 ethAmount, uint256 tokenAmount);
    event SellToken(address seller, uint256 ethAmount, uint256 tokenAmount);
    event SwapTokens(address user1, uint256 token1Amount, address user2, uint256 token2Amount);

    constructor(address tokenAddress, uint256 initialPriceTokenInWei) {
        token = Token(tokenAddress);
        tokenPriceInWei = initialPriceTokenInWei;
    }

    function setTokenPrice(uint256 newPrice) public onlyOwner {
        tokenPriceInWei = newPrice;
    }
    
    function getTokenPrice() public view returns (uint256) {
        return tokenPriceInWei;
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Send some Ether to buy tokens");
        address buyer = msg.sender;
        uint256 ethAmount = msg.value;
        uint256 tokenAmount = ethAmount / tokenPriceInWei; 

        (bool sent) = token.transfer(buyer, tokenAmount);
        require(sent, "Token transfer failed");

        emit BuyToken(buyer, ethAmount, tokenAmount);
    }

    function sellTokens(uint256 _tokenAmount) public {
        address seller = msg.sender;
        uint256 userTokenBalance = token.balanceOf(seller);

        require(userTokenBalance >= _tokenAmount, "Not enough tokens to sell");
        uint256 ethAmount = _tokenAmount * tokenPriceInWei;

        (bool sent) = token.transferFrom(seller, address(this), _tokenAmount);
        require(sent, "Token transfer failed");

        (bool success, ) = seller.call{value: ethAmount}("");
        require(success, "Failed to send ETH to seller");

        emit SellToken(seller, ethAmount, _tokenAmount);
    }

     function swapTokens(address user2, uint256 token2Amount) public {
      address user1 = msg.sender;
        uint256 user1TokenBalance = token.balanceOf(user1);

        require(user1TokenBalance >= token2Amount, "Not enough tokens to swap");

        uint256 token1Amount = token2Amount * tokenPriceInWei; 
        require(token1Amount > 0, "Token1 amount is too low");

        (bool sent1) = token.transfer(user2, token1Amount);
        require(sent1, "Token transfer from user1 to user2 failed");

        
        (bool sent2) = token.transfer(user1, token2Amount);
        require(sent2, "Token transfer from user2 to user1 failed");

        emit SwapTokens(user1, token1Amount, user2, token2Amount);
    } 
}