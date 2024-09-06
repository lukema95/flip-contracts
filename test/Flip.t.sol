// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Flip} from "../src/Flip.sol";

contract FlipTest is Test {
    receive() external payable {}

    Flip public flip;

    address alice = address(0x1);
    address bob = address(0x2);
    address carol = address(0x3);

    function setUp() public {
        vm.prank(alice);
        flip = new Flip(0.001 ether);
    }

    function test_mint() public {
        vm.deal(bob, 10000 ether);
        uint256 totalPrice = 0;
        uint256 totalPriceAfterFee = 0;
        uint256 totalCreatorFee = 0;
        console.log("================================================");
        for (uint256 i = 0; i < 10000; i++) {
            uint256 price = flip.getBuyPrice();
            uint256 priceAfterFee = flip.getBuyPriceAfterFee();
            vm.prank(bob);
            flip.mint{value: priceAfterFee}();
            totalPrice += price;
            totalPriceAfterFee += priceAfterFee;
            totalCreatorFee += price * flip.CREATOR_FEE_PERCENT() / 1 ether;
            if (i % 1000 == 0 || i == 1 || i == 10000) {
                console.log("index:         ", i + 1);
                console.log("price:         ", price);
                console.log("priceAfterFee: ", priceAfterFee);
                console.log("currentSupply: ", flip.currentSupply());
                console.log("totalSupply:   ", flip.totalSupply());
                console.log("----------------------------------------");
            }
        }
        assertEq(flip.totalSupply(), 10000);
        assertEq(flip.currentSupply(), 10000);
        assertEq(flip.balanceOf(bob), 10000);
        assertEq(address(flip).balance, totalPrice);

        console.log("totalPrice:         ||", totalPrice);
        console.log("totalCreatorFee:    ||", totalCreatorFee);
        console.log("totalPriceAfterFee: ||", totalPriceAfterFee);
        assertEq(address(alice).balance, totalCreatorFee);
        assertEq(totalPriceAfterFee, totalPrice + totalCreatorFee);
    }

    function test_mint_and_sell() public {
        test_mint();
        
        uint256 bobBalanceBeforeSell = bob.balance;
        uint256 contractBalanceBeforeSell = address(flip).balance;
        uint256 creatorBalanceBeforeSell = address(alice).balance;
        for (uint256 i = 1; i <= 10000; i++) {
            vm.prank(bob);
            flip.sell(i);
        }
        uint256 bobBalanceAfterSell = bob.balance;
        uint256 contractBalanceAfterSell = address(flip).balance;
        uint256 creatorBalanceAfterSell = address(alice).balance;

        console.log("Bob Balance before sell      ", bobBalanceBeforeSell);
        console.log("Bob Balance after sell       ", bobBalanceAfterSell);
        
        console.log("Contract Balance before sell ", contractBalanceBeforeSell);
        console.log("Contract Balance after sell  ", contractBalanceAfterSell);
        
        console.log("Creator Balance before sell  ", creatorBalanceBeforeSell);
        console.log("Creator Balance after sell   ", creatorBalanceAfterSell);

        uint256 diffContractBalance = contractBalanceBeforeSell - contractBalanceAfterSell;
        uint256 diffBobBalance = bobBalanceAfterSell - bobBalanceBeforeSell;
        uint256 diffCreatorBalance = creatorBalanceAfterSell - creatorBalanceBeforeSell;
        
        assertEq(diffContractBalance, diffBobBalance + diffCreatorBalance);
    }

    function test_deal() public {
        vm.deal(bob, 10000 ether);
        // mint all
        console.log("================================================");
        uint256 bobBalanceBeforeMint = bob.balance;
        uint256 contractBalanceBeforeMint = address(flip).balance;
        for (uint256 i = 0; i < 10000; i++) {
            uint256 price = flip.getBuyPriceAfterFee();
            vm.prank(bob);
            flip.mint{value: price}();
        }

        uint256 contractBalanceAfterMint = address(flip).balance;
        uint256 bobBalanceAfterMint = bob.balance;
        
        console.log("Bob Balance before mint     ", bobBalanceBeforeMint);
        console.log("Bob Balance after mint      ", bobBalanceAfterMint);
        console.log("Contract Balance before mint", contractBalanceBeforeMint);
        console.log("Contract Balance after mint ", contractBalanceAfterMint);

        // sell 1000
        console.log("================================================");
        uint256 creatorBalanceBeforeSell = address(alice).balance;
        uint256 bobBalanceBeforeSell = bob.balance;
        uint256 contractBalanceBeforeSell = address(flip).balance;
        uint256 totalSellPriceAfterFee = 0;
        uint256 totalSellPrice = 0;
        uint256 totalCreatorSellFee = 0;
        for (uint256 i = 1; i <= 2000; i++) {
            uint256 sellPrice = flip.getSellPrice();
            uint256 sellPriceAfterFee = flip.getSellPriceAfterFee();
            
            vm.prank(bob);
            flip.sell(i);
            
            totalSellPriceAfterFee += sellPriceAfterFee;
            totalSellPrice += sellPrice;
            totalCreatorSellFee += sellPrice * flip.CREATOR_FEE_PERCENT() / 1 ether;
            
            if (i % 500 == 0 || i == 1 || i == 2000) {
                console.log("Token ID:            ", i);
                console.log("Creator Fee:         ", sellPrice * flip.CREATOR_FEE_PERCENT() / 1 ether);
                console.log("Sell Price:          ", sellPrice);
                console.log("Sell Price After Fee:", sellPriceAfterFee);
                assertEq(sellPrice, sellPriceAfterFee + sellPrice * flip.CREATOR_FEE_PERCENT() / 1 ether);
                console.log("----------------------------------------");
            }
        }
        uint256 contractBalanceAfterSell = address(flip).balance;
        uint256 bobBalanceAfterSell = bob.balance;
        uint256 creatorBalanceAfterSell = address(alice).balance;

        console.log("Bob Balance before sell      ", bobBalanceBeforeSell);
        console.log("Bob Balance after sell       ", bobBalanceAfterSell);
        
        console.log("Contract Balance before sell ", contractBalanceBeforeSell);
        console.log("Contract Balance after sell  ", contractBalanceAfterSell);
        
        console.log("Total Creator Fee            ", totalCreatorSellFee);
        console.log("Creator Balance before sell  ", creatorBalanceBeforeSell);
        console.log("Creator Balance after sell   ", creatorBalanceAfterSell);
        
        assertEq(bobBalanceAfterSell, bobBalanceBeforeSell + totalSellPriceAfterFee);
        assertEq(creatorBalanceAfterSell, creatorBalanceBeforeSell + totalCreatorSellFee);
        assertEq(contractBalanceAfterSell, contractBalanceBeforeSell - totalSellPrice);
        assertEq(totalSellPrice, totalSellPriceAfterFee + totalCreatorSellFee);

        // buy 200
        console.log("================================================");
        vm.deal(carol, 100000 ether);
        uint256 carolBalanceBeforeBuy = carol.balance;
        uint256 contractBalanceBeforeBuy = address(flip).balance;
        uint256 creatorBalanceBeforeBuy = address(alice).balance;

        uint256 totalBuyPriceAfterFee = 0;
        uint256 totalBuyPrice = 0;
        uint256 totalCreatorBuyFee = 0;
        for (uint256 i = 1; i <= 2000; i++) {
            uint256 buyPrice = flip.getBuyPrice();
            uint256 buyPriceAfterFee = flip.getBuyPriceAfterFee();
            
            vm.prank(carol);
            flip.buy{value: buyPriceAfterFee}(i);

            totalBuyPriceAfterFee += buyPriceAfterFee;
            totalBuyPrice += buyPrice;
            totalCreatorBuyFee += buyPrice * flip.CREATOR_FEE_PERCENT() / 1 ether;
            
            if (i % 500 == 0 || i == 1 || i == 2000) {
                console.log("index:            ", i);
                console.log("buyPrice:         ", buyPrice);
                console.log("creatorFee:       ", buyPrice * flip.CREATOR_FEE_PERCENT() / 1 ether);
                console.log("buyPriceAfterFee: ", buyPriceAfterFee);
                assertEq(buyPrice, buyPriceAfterFee - buyPrice * flip.CREATOR_FEE_PERCENT() / 1 ether);
                console.log("----------------------------------------");

            }
        }
        uint256 contractBalanceAfterBuy = address(flip).balance;
        uint256 carolBalanceAfterBuy = carol.balance;
        uint256 creatorBalanceAfterBuy = address(alice).balance;

        console.log("Carol Balance before buy   ", carolBalanceBeforeBuy);
        console.log("Carol Balance after buy    ", carolBalanceAfterBuy);
        
        console.log("Contract Balance before buy", contractBalanceBeforeBuy);
        console.log("Contract Balance after buy ", contractBalanceAfterBuy);
        
        console.log("Total Creator Buy Fee      ", totalCreatorBuyFee);
        console.log("Creator Balance before buy ", creatorBalanceBeforeBuy);
        console.log("Creator Balance after buy  ", creatorBalanceAfterBuy);

        assertEq(carolBalanceAfterBuy, carolBalanceBeforeBuy - totalBuyPriceAfterFee);
        assertEq(creatorBalanceAfterBuy, creatorBalanceBeforeBuy + totalCreatorBuyFee);
        assertEq(contractBalanceAfterBuy, contractBalanceBeforeBuy + totalBuyPrice);
        assertEq(totalBuyPrice, totalBuyPriceAfterFee - totalCreatorBuyFee);

        /*
        // sell 1000
        console.log("================================================");
        contractBalanceBeforeSell = address(flip).balance;
        creatorBalanceBeforeSell = address(alice).balance;
        uint256 carolBalanceBeforeSell = carol.balance;

        totalSellPriceAfterFee = 0;
        totalSellPrice = 0;
        totalCreatorSellFee = 0;
        for (uint256 i = 1; i <= 1000; i++) {
            uint256 sellPrice = flip.getSellPrice();
            uint256 sellPriceAfterFee = flip.getSellPriceAfterFee();
            
            vm.prank(carol);
            flip.sell(i);
            
            totalSellPriceAfterFee += sellPriceAfterFee;
            totalSellPrice += sellPrice;
            totalCreatorSellFee += sellPrice * flip.CREATOR_FEE_PERCENT() / 1 ether;
            
            if (i % 100 == 0 || i == 1 || i == 1000) {
                console.log("index:             ", i);
                console.log("sellPriceAfterFee: ", sellPriceAfterFee);
                console.log("creatorFee:        ", sellPrice * flip.CREATOR_FEE_PERCENT() / 1 ether);
                console.log("sellPrice:         ", sellPrice);
                assertEq(sellPrice, sellPriceAfterFee + sellPrice * flip.CREATOR_FEE_PERCENT() / 1 ether);
                console.log("----------------------------------------");
            }
        }

        contractBalanceAfterSell = address(flip).balance;
        creatorBalanceAfterSell = address(alice).balance;
        uint256 carolBalanceAfterSell = carol.balance;

        console.log("Carol Balance before sell   ", carolBalanceBeforeSell);
        console.log("Carol Balance after sell    ", carolBalanceAfterSell);
        
        console.log("Contract Balance before sell ", contractBalanceBeforeSell);
        console.log("Contract Balance after sell  ", contractBalanceAfterSell);
        
        console.log("Total Creator Sell Fee      ", totalCreatorSellFee);
        console.log("Creator Balance before sell  ", creatorBalanceBeforeSell);
        console.log("Creator Balance after sell   ", creatorBalanceAfterSell);

        assertEq(carolBalanceAfterSell, carolBalanceBeforeSell + totalSellPriceAfterFee);
        assertEq(creatorBalanceAfterSell, creatorBalanceBeforeSell + totalCreatorSellFee);
        assertEq(contractBalanceAfterSell, contractBalanceBeforeSell - totalSellPrice);
        assertEq(totalSellPrice, totalSellPriceAfterFee + totalCreatorSellFee);
        */
    }

    function testPriceCurve() public {
        console.log("Price at 0     supply:", flip.calculatePrice(0));
        console.log("Price at 500   supply:", flip.calculatePrice(500));
        console.log("Price at 1000  supply:", flip.calculatePrice(1000));
        console.log("Price at 2500  supply:", flip.calculatePrice(2500));
        console.log("Price at 5000  supply:", flip.calculatePrice(5000));
        console.log("Price at 7500  supply:", flip.calculatePrice(7500));
        console.log("Price at 10000 supply:", flip.calculatePrice(10000));
    }
}