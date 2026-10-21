// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PetPark} from "../contracts/instructor/PetPark.sol";
import {SnackToken} from "../contracts/instructor/SnackToken.sol";
import {TamagotchiPlus} from "../contracts/solutions/TamagotchiPlus.sol";

contract TamagotchiPlusTest is Test {
    PetPark park;
    SnackToken snack;
    TamagotchiPlus pet;
    address ana = makeAddr("ana");
    address bia = makeAddr("bia");
    address caio = makeAddr("caio");

    function setUp() public {
        vm.warp(1_760_000_000);
        park = new PetPark();
        snack = park.snack();
        park.setFaucet(500, 0);
        vm.prank(ana);
        pet = new TamagotchiPlus("Plus", address(park));
        address[3] memory kids = [ana, bia, caio];
        for (uint256 i; i < 3; i++) {
            vm.startPrank(kids[i]);
            park.claim();
            snack.approve(address(pet), 1000);
            vm.stopPrank();
        }
    }

    function test_poopAndClean() public {
        assertEq(pet.mood(), unicode"🥰");
        vm.expectRevert("Already clean!");
        pet.clean();
        vm.warp(block.timestamp + 30 minutes);
        vm.prank(ana);
        pet.feed();
        assertEq(pet.poops(), 3);
        assertEq(pet.mood(), unicode"🤢");
        vm.prank(bia);
        vm.expectRevert("Eww, too dirty to play. clean() first!");
        pet.play();
        vm.prank(bia);
        pet.clean();
        assertEq(pet.poops(), 0);
        vm.prank(bia);
        pet.play();
    }

    function test_levelsAndBestFriend() public {
        vm.prank(ana);
        pet.feed(); // owner: xp but no friendship
        vm.prank(bia);
        pet.feed();
        for (uint256 i; i < 3; i++) {
            vm.prank(caio);
            pet.feed();
        }
        assertEq(pet.xp(), 5);
        assertEq(pet.level(), 1);
        assertEq(pet.bestFriend(), caio);
        assertEq(pet.friendship(ana), 0);
    }

    function test_rename() public {
        vm.prank(bia);
        vm.expectRevert("Only my owner can do that!");
        pet.rename("Hacked");
        vm.prank(ana);
        pet.rename("Plus Ultra");
        assertEq(pet.name(), "Plus Ultra");
    }
}
