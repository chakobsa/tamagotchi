// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PetPark} from "../contracts/instructor/PetPark.sol";
import {SnackToken} from "../contracts/instructor/SnackToken.sol";
import {Tamagotchi} from "../contracts/student/Tamagotchi.sol";

/// vm.cool exists in forge 1.x but not in the vendored forge-std 1.9.4 interface
interface VmCool {
    function cool(address target) external;
}

contract TamagotchiTest is Test {
    PetPark park;
    SnackToken snack;
    Tamagotchi pet;

    address teacher = makeAddr("teacher");
    address ana = makeAddr("ana");
    address bia = makeAddr("bia");

    function setUp() public {
        vm.warp(1_760_000_000); // a realistic "now"
        vm.prank(teacher);
        park = new PetPark();
        snack = park.snack();

        vm.prank(ana, ana);
        pet = new Tamagotchi("Bolinha", address(park));
    }

    function _claimAndApprove(address who, address spender) internal {
        vm.startPrank(who);
        park.claim();
        snack.approve(spender, 1000);
        vm.stopPrank();
    }

    // ---------------------------------------------------------------- park

    function test_parkHoldsWholeSupply() public view {
        assertEq(snack.decimals(), 0);
        assertEq(snack.balanceOf(address(park)), 1_000_000);
    }

    function test_petRegisteredOnBirth() public view {
        assertEq(park.petCount(), 1);
        assertEq(park.allPets()[0], address(pet));
        assertTrue(park.isPet(address(pet)));
        assertEq(pet.owner(), ana);
        assertEq(pet.name(), "Bolinha");
    }

    function test_cannotRegisterTwice() public {
        vm.prank(address(pet));
        vm.expectRevert("Park: already registered");
        park.register();
    }

    function test_faucetCooldown() public {
        vm.startPrank(ana);
        park.claim();
        assertEq(snack.balanceOf(ana), 50);
        assertEq(park.secondsUntilClaim(ana), 180);

        vm.expectRevert("Faucet: too soon, try again in a few minutes");
        park.claim();

        vm.warp(block.timestamp + 3 minutes);
        park.claim();
        assertEq(snack.balanceOf(ana), 100);
        vm.stopPrank();
    }

    function test_onlyTeacherTunesFaucet() public {
        vm.prank(ana);
        vm.expectRevert("Park: only the teacher");
        park.setFaucet(500, 0);

        vm.prank(teacher);
        park.setFaucet(500, 0);
        vm.startPrank(bia);
        park.claim();
        park.claim(); // no cooldown during happy hour
        vm.stopPrank();
        assertEq(snack.balanceOf(bia), 1000);
    }

    // ---------------------------------------------------------------- pet stats

    function test_newbornIsHappy() public view {
        assertEq(pet.hunger(), 0);
        assertEq(pet.boredom(), 0);
        assertEq(pet.tiredness(), 0);
        assertTrue(pet.isAlive());
        assertEq(pet.mood(), unicode"😄");
    }

    function test_statsGrowWithTime() public {
        vm.warp(block.timestamp + 10 minutes);
        assertEq(pet.hunger(), 20);
        assertEq(pet.boredom(), 30);
        assertEq(pet.tiredness(), 20);
        assertEq(pet.ageInMinutes(), 10);
        assertEq(pet.mood(), unicode"😄");

        vm.warp(block.timestamp + 10 minutes); // boredom 60
        assertEq(pet.mood(), unicode"😐");

        vm.warp(block.timestamp + 10 minutes); // boredom 90
        assertEq(pet.mood(), unicode"😫");
    }

    function test_diesAfter50MinutesWithoutFood() public {
        vm.warp(block.timestamp + 49 minutes);
        assertTrue(pet.isAlive());
        vm.warp(block.timestamp + 1 minutes);
        assertFalse(pet.isAlive());
        assertEq(pet.mood(), unicode"💀");
        assertEq(pet.boredom(), 100); // capped
    }

    // ---------------------------------------------------------------- actions

    function test_hugIsFreeForAnyone() public {
        vm.prank(bia);
        pet.hug();
        vm.prank(ana);
        pet.hug();
        assertEq(pet.hugs(), 2);
    }

    function test_feedNeedsApprove() public {
        vm.prank(bia);
        park.claim();
        vm.prank(bia);
        vm.expectRevert("SNACK: allowance too low - did you approve() first?");
        pet.feed();
    }

    function test_feedNeedsBalance() public {
        vm.prank(bia);
        snack.approve(address(pet), 1000);
        vm.prank(bia);
        vm.expectRevert("SNACK: not enough SNACK - visit the faucet");
        pet.feed();
    }

    function test_friendCanFeedAndSnackGoesBackToPark() public {
        _claimAndApprove(bia, address(pet));
        vm.warp(block.timestamp + 20 minutes);
        assertEq(pet.hunger(), 40);

        uint256 parkBefore = snack.balanceOf(address(park));
        vm.prank(bia);
        pet.feed();

        assertEq(pet.hunger(), 0);
        assertEq(snack.balanceOf(bia), 40);
        assertEq(snack.balanceOf(address(park)), parkBefore + 10);
    }

    function test_play() public {
        _claimAndApprove(bia, address(pet));
        vm.warp(block.timestamp + 10 minutes);
        vm.prank(bia);
        pet.play();
        assertEq(pet.boredom(), 0);
        assertEq(snack.balanceOf(bia), 45);
    }

    function test_tooTiredToPlay() public {
        _claimAndApprove(ana, address(pet));
        vm.startPrank(ana);
        vm.warp(block.timestamp + 20 minutes);
        pet.feed();
        vm.warp(block.timestamp + 20 minutes); // tiredness 80
        vm.expectRevert("Too tired to play... my owner should call sleep()");
        pet.play();
        vm.stopPrank();
    }

    function test_sleepOnlyOwnerAndBlocksPlay() public {
        _claimAndApprove(ana, address(pet));
        vm.warp(block.timestamp + 30 minutes);

        vm.prank(bia);
        vm.expectRevert("Only my owner can do that!");
        pet.sleep();

        vm.startPrank(ana);
        pet.sleep();
        assertTrue(pet.isSleeping());
        assertEq(pet.mood(), unicode"😴");
        assertEq(pet.tiredness(), 0);

        vm.expectRevert("Shhh... I'm sleeping. Try again in a moment");
        pet.play();

        pet.feed(); // you can still feed a sleeping pet
        pet.hug();

        vm.warp(block.timestamp + 2 minutes);
        assertFalse(pet.isSleeping());
        assertEq(pet.tiredness(), 0);
        pet.play();
        vm.stopPrank();
    }

    function test_deadPetRejectsEverythingButRevive() public {
        _claimAndApprove(ana, address(pet));
        _claimAndApprove(bia, address(pet));
        vm.warp(block.timestamp + 60 minutes);

        vm.prank(bia);
        vm.expectRevert("RIP... this pet is dead. Its owner can call revive()");
        pet.feed();
        vm.prank(bia);
        vm.expectRevert("RIP... this pet is dead. Its owner can call revive()");
        pet.hug();
        vm.prank(bia);
        vm.expectRevert("Only my owner can do that!");
        pet.revive();

        vm.prank(ana);
        pet.revive();
        assertTrue(pet.isAlive());
        assertEq(pet.hunger(), 0);
        assertEq(snack.balanceOf(ana), 0);

        vm.prank(ana);
        vm.expectRevert("I'm alive already!");
        pet.revive();
    }

    function test_statusMatchesGetters() public {
        vm.warp(block.timestamp + 7 minutes);
        (uint256 h, uint256 b, uint256 t, uint256 hg, bool alive, bool sleeping) = pet.status();
        assertEq(h, pet.hunger());
        assertEq(b, pet.boredom());
        assertEq(t, pet.tiredness());
        assertEq(hg, 0);
        assertTrue(alive);
        assertFalse(sleeping);
    }

    // Wallets estimate gas a moment BEFORE a transaction runs. If an action got more expensive as
    // time passes, an estimate made right after feed() (same block) would be too low later -> out of gas.
    function test_gasCostDoesNotGrowWithTime() public {
        _claimAndApprove(ana, address(pet));
        vm.startPrank(ana);
        pet.hug();   // hugs 0 -> 1, so the measured hugs are nonzero -> nonzero
        pet.feed();  // lastFed == block.timestamp now

        VmCool(address(vm)).cool(address(pet)); // make its storage "cold" again, like a fresh transaction
        uint256 g = gasleft();
        pet.hug();
        uint256 sameBlock = g - gasleft();

        vm.warp(block.timestamp + 7 minutes);
        VmCool(address(vm)).cool(address(pet)); // make its storage "cold" again, like a fresh transaction
        g = gasleft();
        pet.hug();
        uint256 later = g - gasleft();
        vm.stopPrank();

        assertGe(sameBlock, later, "hug() costs more later than right after feed()");
    }

    function test_manyPets() public {
        for (uint256 i = 0; i < 40; i++) {
            address kid = address(uint160(1000 + i));
            vm.prank(kid, kid);
            new Tamagotchi("Pet", address(park));
        }
        assertEq(park.petCount(), 41);
    }
}
