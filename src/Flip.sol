// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

contract Flip is ERC721, ERC721Holder, Ownable {
    using Math for uint256;

    struct Order {
        address seller;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MINT_PRICE = 0.001 ether;
    uint256 public totalSupply;
    uint256 public initialPrice; 

    // Limit Order Book
    mapping(uint256 => Order) public limitOrders;
    uint256[] public orderedLimitOrders;
    uint256[] public activeLimitOrders;
    mapping(uint256 => uint256) public limitOrderIndex;
    mapping(uint256 => uint256) public orderedLimitOrderIndex;
    uint256 public limitOrderCount;

    // Market Order Book
    uint256[] public marketOrders;
    mapping(uint256 => uint256) public marketOrderIndex;
    uint256 public marketOrderCount;

    constructor() ERC721("FlipNFT", "FLIP") Ownable(msg.sender) {
        totalSupply = 0;
    }

    function mint() public payable {
        require(msg.value >= MINT_PRICE, "Insufficient payment");
        require(totalSupply <= MAX_SUPPLY, "Max supply reached");

        uint256 tokenId = totalSupply + 1;
        totalSupply = tokenId;
        _safeMint(msg.sender, tokenId);
    }

    function createLimitSellOrder(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(getApproved(tokenId) == address(this), "Contract not approved");

        limitOrderCount++;
        limitOrders[limitOrderCount] = Order({
            seller: msg.sender,
            tokenId: tokenId,
            price: price,
            isActive: true
        });

        activeLimitOrders.push(limitOrderCount);
        limitOrderIndex[limitOrderCount] = activeLimitOrders.length - 1;

        insertOrderedLimitOrder(limitOrderCount, price);
    }

    function insertOrderedLimitOrder(uint256 orderId, uint256 price) internal {
        orderedLimitOrders.push(orderId);
        uint256 i = orderedLimitOrders.length - 1;
        while (i > 0 && limitOrders[orderedLimitOrders[i - 1]].price > price) {
            orderedLimitOrders[i] = orderedLimitOrders[i - 1];
            orderedLimitOrderIndex[orderedLimitOrders[i]] = i;
            i--;
        }
        orderedLimitOrders[i] = orderId;
        orderedLimitOrderIndex[orderId] = i;
    }

    function cancelLimitSellOrder(uint256 orderId) external {
        Order storage order = limitOrders[orderId];
        require(order.seller == msg.sender, "Not the seller");
        require(order.isActive, "Order not active");

        removeOrderedLimitOrder(orderId);
    }

    function removeOrderedLimitOrder(uint256 orderId) internal {
        uint256 index = orderedLimitOrderIndex[orderId];
        uint256 lastIndex = orderedLimitOrders.length - 1;
        
        if (index != lastIndex) {
            uint256 lastOrderId = orderedLimitOrders[lastIndex];
            orderedLimitOrders[index] = lastOrderId;
            orderedLimitOrderIndex[lastOrderId] = index;
        }
        
        orderedLimitOrders.pop();
        delete orderedLimitOrderIndex[orderId];
    }

    function buyLimitOrder(uint256 orderId) external payable nonReentrant {
        Order storage order = limitOrders[orderId];
        require(order.isActive, "Order not active");
        require(msg.value >= order.price, "Insufficient payment");

        address seller = order.seller;
        uint256 tokenId = order.tokenId;

        order.isActive = false;
        _transfer(seller, msg.sender, tokenId);
        
        payable(seller).transfer(msg.value);
    }

    function buyMarketOrder(uint256 tokenId) public payable {
        require(ownerOf(tokenId) == address(this), "Token is not available for sale");
        uint256 price = getBuyPrice(); 
        require(msg.value >= price, "Insufficient payment");

        _transfer(address(this), msg.sender, tokenId);

        // Remove token from availableTokens
        removeAvailableToken(tokenId);

        accumulatedBuyCount = accumulatedBuyCount + 1;  
    }

    function quickBuyMarketOrder() public payable {
        require(availableTokens.length > 0, "No tokens available for quick buy");
        uint256 price = getBuyPrice(); 
        require(msg.value >= price, "Insufficient payment");

        uint256 tokenId = availableTokens[availableTokens.length - 1];
        _transfer(address(this), msg.sender, tokenId);

        // Remove token from availableTokens
        removeAvailableToken(tokenId);

        accumulatedBuyCount = accumulatedBuyCount + 1;
    }

    function sellMarketOrder(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender(), "Caller is not owner");
        uint256 price = getSellPrice();

        _transfer(_msgSender(), address(this), tokenId);
        (bool success, ) = _msgSender().call{value: price}("");
        require(success, "Transfer failed");

        // Add token to availableTokens
        availableTokens.push(tokenId);

        accumulatedSellCount = accumulatedSellCount + 1;
    }
      
    function calculatePrice(bool isBuy) public view returns (uint256) {
        return 0;
    }

    function curve(uint256 x) public pure returns (uint256) {
        return x * x;
    }

    function getBuyPrice() public view returns (uint256) {
        return calculatePrice(true);
    }

    function getSellPrice() public view returns (uint256) {
        return calculatePrice(false);
    }

    function removeAvailableToken(uint256 tokenId) internal {
        uint256 index = tokenIndex[tokenId];
        uint256 lastIndex = availableTokens.length - 1;
        uint256 lastToken = availableTokens[lastIndex];

        availableTokens[index] = lastToken;
        tokenIndex[lastToken] = index;

        availableTokens.pop();
    }

    function getLowestLimitOrder() public view returns (uint256) {
        require(orderedLimitOrders.length > 0, "No active limit orders");
        return orderedLimitOrders[0];
    }
}