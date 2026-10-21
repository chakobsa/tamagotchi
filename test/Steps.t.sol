// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PetPark} from "../contracts/instructor/PetPark.sol";
import {SnackToken} from "../contracts/instructor/SnackToken.sol";
import {Tamagotchi as Egg} from "../contracts/student/steps/Step1_Egg.sol";
import {Tamagotchi as Hungry} from "../contracts/student/steps/Step2_Hunger.sol";
import {Tamagotchi as Playful} from "../contracts/student/steps/Step3_PlayAndSleep.sol";
import {Tamagotchi as Complete} from "../contracts/student/Tamagotchi.sol";

/// Every code-along checkpoint must deploy, register with the park and do what its slide says.
contract StepsTest is Test {
    PetPark park;
    SnackToken snack;
    address ana = makeAddr("ana");
    address bia = makeAddr("bia");

    function setUp() public {
        vm.warp(1_760_000_000);
        park = new PetPark();
        snack = park.snack();
        vm.prank(ana);
        park.claim();
    }

    function test_starterCompilesAndHasTheInterfaces() public {
        // The starter is just interfaces + an empty contract: deploying it must work in Remix.
        bytes memory code = vm.getCode("Step0_Starter.sol:Tamagotchi");
        address empty;
        assembly { empty := create(0, add(code, 0x20), mload(code)) }
        assertTrue(empty != address(0));
    }

    function test_step1_eggRegistersAndHugs() public {
        vm.prank(ana);
        Egg egg = new Egg("Ovo", address(park));
        assertEq(park.petCount(), 1);
        assertEq(egg.owner(), ana);
        vm.prank(bia);
        egg.hug();
        assertEq(egg.hugs(), 1);
        vm.warp(block.timestamp + 5 minutes);
        assertEq(egg.ageInMinutes(), 5);
    }

    function test_step2_hungerAndFeed() public {
        vm.startPrank(ana);
        Hungry pet = new Hungry("Fome", address(park));
        vm.warp(block.timestamp + 10 minutes);
        assertEq(pet.hunger(), 20);
        vm.expectRevert("SNACK: allowance too low - did you approve() first?");
        pet.feed();
        snack.approve(address(pet), 200);
        pet.feed();
        assertEq(pet.hunger(), 0);
        vm.warp(block.timestamp + 50 minutes);
        assertFalse(pet.isAlive());
        vm.expectRevert("RIP... this pet is dead. Its owner can call revive()");
        pet.hug();
        vm.stopPrank();
    }

    function test_step3_playSleepAndOwnerOnly() public {
        vm.startPrank(ana);
        Playful pet = new Playful("Sono", address(park));
        snack.approve(address(pet), 200);
        vm.warp(block.timestamp + 10 minutes);
        assertEq(pet.boredom(), 30);
        pet.play();
        assertEq(pet.boredom(), 0);
        pet.sleep();
        vm.expectRevert("Shhh... I'm sleeping. Try again in a moment");
        pet.play();
        vm.stopPrank();
        vm.prank(bia);
        vm.expectRevert("Only my owner can do that!");
        pet.sleep();
    }

    function test_step4_isTheCompletePet() public {
        vm.prank(ana);
        Complete pet = new Complete("Final", address(park));
        assertEq(pet.mood(), unicode"😄");
        assertEq(pet.REVIVE_COST(), 50);
    }

    function test_oneStudentManyVersionsAllRegister() public {
        vm.startPrank(ana);
        new Egg("v1", address(park));
        new Hungry("v2", address(park));
        new Playful("v3", address(park));
        new Complete("v4", address(park));
        vm.stopPrank();
        assertEq(park.petCount(), 4);
    }
}
