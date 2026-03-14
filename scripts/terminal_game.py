#!/usr/bin/env python3
from _future_ import annotations

import argparse
import random
from collections import Counter
from dataclasses import dataclass
from itertools import combinations
from typing import Sequence


MAX_HP = 10
STARTING_DECK = [
    "fire",
    "fire",
    "poison",
    "poison",
    "heal",
    "heal",
    "heal",
    "chaos",
    "chaos",
    "chaos",
    "chaos",
    "chaos",
]
CARD_LABELS = {
    "fire": "Fire",
    "poison": "Poison",
    "heal": "Heal",
    "chaos": "Chaos",
}
CARD_ALIASES = {
    "f": "fire",
    "fire": "fire",
    "p": "poison",
    "poison": "poison",
    "h": "heal",
    "heal": "heal",
    "c": "chaos",
    "chaos": "chaos",
}


@dataclass(frozen=True)
class PotionResult:
    kind: str
    label: str
    amount: int = 0


@dataclass(frozen=True)
class CraftPlan:
    used_indices: tuple[int, int, int, int]
    potion_a: tuple[str, str]
    potion_b: tuple[str, str]


class PotionRouletteTerminal:
    def _init_(self, seed: int | None = None) -> None:
        self.seed = seed
        self.rng = random.Random(seed)
        self.player_hp = MAX_HP
        self.ai_hp = MAX_HP
        self.turn_count = 1
        self.is_player_turn = True
        self.game_over = False
        self.player_hand = self._build_starting_deck()
        self.ai_hand = self._build_starting_deck()
        self.current_left_potion: list[str] = []
        self.current_right_potion: list[str] = []

    def play(self) -> int:
        self._print_intro()

        while not self.game_over:
            keep_playing = self._play_turn()
            if not keep_playing:
                print("\nMatch ended early.")
                return 0

        print()
        if self.player_hp <= 0 and self.ai_hp <= 0:
            print("Result: Draw")
        elif self.player_hp <= 0:
            print("Result: AI wins")
        else:
            print("Result: Player wins")
        return 0

    def _play_turn(self) -> bool:
        brewer = "Player" if self.is_player_turn else "AI"
        active_hand = self.player_hand if self.is_player_turn else self.ai_hand
        refill_notice = self._refill_hand_if_needed(active_hand, brewer)

        print("\n" + "=" * 56)
        print(f"Turn {self.turn_count}: {brewer} brews")
        if refill_notice:
            print(refill_notice)
        print(f"Player HP: {self.player_hp:>2}   AI HP: {self.ai_hp:>2}")
        self._print_visible_cards()

        if self.is_player_turn:
            crafted_potions = self._prompt_player_potions()
            if crafted_potions is None:
                return False
            self.current_left_potion, self.current_right_potion = crafted_potions
            print("You brew two hidden potions and slide them to the AI.")
            print("Visible cards after brewing:")
            self._print_visible_cards()
            chosen_index = self._choose_ai_potion()
            print(f"AI chooses Potion {'A' if chosen_index == 0 else 'B'}")
        else:
            self.current_left_potion, self.current_right_potion = self._craft_ai_potions()
            print("AI brews two hidden potions.")
            print("Visible cards after brewing:")
            self._print_visible_cards()
            chosen_index = self._prompt_for_choice()
            if chosen_index is None:
                return False

        self._resolve_turn(chosen_index)
        self._check_game_over()
        if not self.game_over:
            self.is_player_turn = not self.is_player_turn
            self.turn_count += 1
        return True

    def _build_starting_deck(self) -> list[str]:
        return STARTING_DECK.copy()

    def _refill_hand_if_needed(self, hand: list[str], owner: str) -> str:
        if len(hand) >= 4:
            return ""
        hand.extend(self._build_starting_deck())
        return f"{owner} hand refilled."

    def _print_visible_cards(self) -> None:
        print(f"Your cards: {self._format_card_counts(self.player_hand)}")
        print(f"AI cards left: {self._format_card_counts(self.ai_hand)}")

    def _prompt_player_potions(self) -> tuple[list[str], list[str]] | None:
        print("Craft Potion A, then Potion B, using two cards each.")
        snapshot = self.player_hand.copy()

        potion_a = self._prompt_potion_cards(self.player_hand, "Potion A")
        if potion_a is None:
            self.player_hand = snapshot
            return None

        potion_b = self._prompt_potion_cards(self.player_hand, "Potion B")
        if potion_b is None:
            self.player_hand = snapshot
            return None

        return potion_a, potion_b

    def _prompt_potion_cards(self, hand: list[str], potion_label: str) -> list[str] | None:
        while True:
            print(f"{potion_label} options from your cards: {self._format_card_counts(hand)}")
            try:
                raw = input(f"{potion_label} cards (example: fire poison, or Q to quit): ").strip().lower()
            except EOFError:
                return None
            except KeyboardInterrupt:
                print()
                return None

            if raw in {"q", "quit", "exit"}:
                return None

            selected_cards = self._parse_card_pair(raw)
            if selected_cards is None:
                print("Enter exactly two cards, like 'fire poison' or 'f p'.")
                continue

            if not self._has_cards(hand, selected_cards):
                print("You do not have those two cards available.")
                continue

            for card in selected_cards:
                hand.remove(card)
            return list(selected_cards)

    def _parse_card_pair(self, raw: str) -> tuple[str, str] | None:
        tokens = raw.replace(",", " ").split()
        if len(tokens) != 2:
            return None

        normalized: list[str] = []
        for token in tokens:
            card_name = CARD_ALIASES.get(token)
            if card_name is None:
                return None
            normalized.append(card_name)
        return normalized[0], normalized[1]

    def _has_cards(self, hand: Sequence[str], selected_cards: Sequence[str]) -> bool:
        hand_counts = Counter(hand)
        needed_counts = Counter(selected_cards)
        for card, count in needed_counts.items():
            if hand_counts[card] < count:
                return False
        return True

    def _craft_ai_potions(self) -> tuple[list[str], list[str]]:
        plans = list(self._iter_craft_plans(self.ai_hand))
        scored_plans: list[tuple[float, CraftPlan]] = []
        for plan in plans:
            scored_plans.append((self._score_ai_craft_plan(plan), plan))

        best_score = max(score for score, _plan in scored_plans)
        best_plans = [plan for score, plan in scored_plans if score == best_score]
        chosen_plan = self.rng.choice(best_plans)

        for index in sorted(chosen_plan.used_indices, reverse=True):
            self.ai_hand.pop(index)

        if self.rng.randrange(2) == 0:
            return list(chosen_plan.potion_a), list(chosen_plan.potion_b)
        return list(chosen_plan.potion_b), list(chosen_plan.potion_a)

    def _iter_craft_plans(self, hand: Sequence[str]) -> Sequence[CraftPlan]:
        seen: set[tuple[tuple[str, str], tuple[str, str], tuple[int, int, int, int]]] = set()
        for used_indices in combinations(range(len(hand)), 4):
            cards = [hand[index] for index in used_indices]
            pairings = (
                ((cards[0], cards[1]), (cards[2], cards[3])),
                ((cards[0], cards[2]), (cards[1], cards[3])),
                ((cards[0], cards[3]), (cards[1], cards[2])),
            )
            for potion_a, potion_b in pairings:
                plan_key = (
                    tuple(sorted(potion_a)),
                    tuple(sorted(potion_b)),
                    tuple(used_indices),
                )
                if plan_key in seen:
                    continue
                seen.add(plan_key)
                yield CraftPlan(
                    used_indices=tuple(used_indices),
                    potion_a=(potion_a[0], potion_a[1]),
                    potion_b=(potion_b[0], potion_b[1]),
                )

    def _score_ai_craft_plan(self, plan: CraftPlan) -> float:
        potion_a_score = self._score_result_for_ai(self._evaluate_potion(*plan.potion_a), target_is_player=True)
        potion_b_score = self._score_result_for_ai(self._evaluate_potion(*plan.potion_b), target_is_player=False)
        choice_a = potion_a_score + potion_b_score

        potion_b_player_score = self._score_result_for_ai(self._evaluate_potion(*plan.potion_b), target_is_player=True)
        potion_a_self_score = self._score_result_for_ai(self._evaluate_potion(*plan.potion_a), target_is_player=False)
        choice_b = potion_b_player_score + potion_a_self_score

        return min(choice_a, choice_b) * 10 + choice_a + choice_b

    def _score_result_for_ai(self, result: PotionResult, target_is_player: bool) -> int:
        if result.kind == "damage":
            return result.amount if target_is_player else -result.amount
        if result.kind == "heal":
            return -result.amount if target_is_player else result.amount
        return 0

    def _prompt_for_choice(self) -> int | None:
        print("Potion A: Hidden")
        print("Potion B: Hidden")
        while True:
            try:
                raw = input("Choose Potion [A/B] or quit [Q]: ").strip().lower()
            except EOFError:
                return None
            except KeyboardInterrupt:
                print()
                return None
            if raw in {"a", "1"}:
                return 0
            if raw in {"b", "2"}:
                return 1
            if raw in {"q", "quit", "exit"}:
                return None
            print("Please type A, B, or Q.")

    def _choose_ai_potion(self) -> int:
        return self.rng.randrange(2)

    def _resolve_turn(self, chosen_index: int) -> None:
        chosen_label = "Potion A" if chosen_index == 0 else "Potion B"
        other_label = "Potion B" if chosen_index == 0 else "Potion A"
        chosen_potion = self.current_left_potion if chosen_index == 0 else self.current_right_potion
        other_potion = self.current_right_potion if chosen_index == 0 else self.current_left_potion
        chooser_is_player = not self.is_player_turn
        chooser_label = "Player" if chooser_is_player else "AI"
        brewer_label = "Player" if self.is_player_turn else "AI"

        print(f"{chooser_label} drinks {chosen_label}.")
        print("Revealed potions:")
        print(f"  Potion A: {self._format_potion(self.current_left_potion)}")
        print(f"  Potion B: {self._format_potion(self.current_right_potion)}")
        print(f"  {other_label} goes back to {brewer_label}.")

        self._apply_potion_to_target(chosen_potion, target_is_player=chooser_is_player, potion_label=chosen_label)
        self._apply_potion_to_target(other_potion, target_is_player=self.is_player_turn, potion_label=other_label)

        self._clamp_health()
        print(f"HP now -> Player: {self.player_hp} | AI: {self.ai_hp}")

    def _apply_potion_to_target(self, potion: Sequence[str], target_is_player: bool, potion_label: str) -> None:
        target_label = "Player" if target_is_player else "AI"
        result = self._evaluate_potion(potion[0], potion[1])
        print(f"  {potion_label} goes to {target_label}: {self._format_potion(potion)}")
        self._apply_result(result, target_is_player)

    def _evaluate_potion(self, card1: str, card2: str) -> PotionResult:
        cards = sorted((card1, card2))

        if cards == ["fire", "fire"]:
            return PotionResult(kind="damage", amount=2, label="Fire + Fire")
        if cards == ["poison", "poison"]:
            return PotionResult(kind="damage", amount=2, label="Poison + Poison")
        if cards == ["fire", "poison"]:
            return PotionResult(kind="damage", amount=3, label="Fire + Poison")
        if cards == ["heal", "heal"]:
            return PotionResult(kind="heal", amount=2, label="Heal + Heal")
        if cards == ["chaos", "heal"]:
            return PotionResult(kind="random_heal", amount=1, label="Heal + Chaos")
        if cards == ["chaos", "fire"]:
            return PotionResult(kind="random_damage", amount=1, label="Fire + Chaos")
        if cards == ["chaos", "chaos"]:
            return PotionResult(kind="chaos_chaos", label="Chaos + Chaos")
        return PotionResult(kind="nothing", label="No Effect")

    def _apply_result(self, result: PotionResult, target_is_player: bool) -> None:
        target_label = "Player" if target_is_player else "AI"

        if result.kind == "damage":
            if target_is_player:
                self.player_hp -= result.amount
            else:
                self.ai_hp -= result.amount
            print(f"    {target_label} takes {result.amount} damage from {result.label}.")
            return

        if result.kind == "heal":
            if target_is_player:
                self.player_hp += result.amount
            else:
                self.ai_hp += result.amount
            print(f"    {target_label} heals {result.amount} from {result.label}.")
            return

        if result.kind == "random_heal":
            heal_player = self.rng.randrange(2) == 0
            if heal_player:
                self.player_hp += result.amount
                print(f"    Random heal from {result.label} goes to Player for {result.amount}.")
            else:
                self.ai_hp += result.amount
                print(f"    Random heal from {result.label} goes to AI for {result.amount}.")
            return

        if result.kind == "random_damage":
            damage_player = self.rng.randrange(2) == 0
            if damage_player:
                self.player_hp -= result.amount
                print(f"    Random damage from {result.label} hits Player for {result.amount}.")
            else:
                self.ai_hp -= result.amount
                print(f"    Random damage from {result.label} hits AI for {result.amount}.")
            return

        if result.kind == "chaos_chaos":
            self._apply_chaos_chaos()
            return

        print(f"    {result.label} fizzles with no extra effect.")

    def _apply_chaos_chaos(self) -> None:
        random_target_is_player = self.rng.randrange(2) == 0
        random_effect = self.rng.randrange(4)
        target_label = "Player" if random_target_is_player else "AI"

        if random_effect == 0:
            if random_target_is_player:
                self.player_hp -= 1
            else:
                self.ai_hp -= 1
            print(f"    Chaos + Chaos damages {target_label} by 1.")
            return

        if random_effect == 1:
            if random_target_is_player:
                self.player_hp += 1
            else:
                self.ai_hp += 1
            print(f"    Chaos + Chaos heals {target_label} by 1.")
            return

        if random_effect == 2:
            if random_target_is_player:
                self.player_hp -= 2
            else:
                self.ai_hp -= 2
            print(f"    Chaos + Chaos slams {target_label} for 2 damage.")
            return

        print("    Chaos + Chaos sparkles and does nothing.")

    def _format_potion(self, potion: Sequence[str]) -> str:
        return " + ".join(CARD_LABELS[card] for card in potion)

    def _format_card_counts(self, cards: Sequence[str]) -> str:
        if not cards:
            return "None"

        counts = Counter(cards)
        ordered_cards = ["fire", "poison", "heal", "chaos"]
        parts = [f"{CARD_LABELS[card]} x{counts[card]}" for card in ordered_cards if counts[card] > 0]
        return ", ".join(parts)

    def _clamp_health(self) -> None:
        self.player_hp = max(0, min(MAX_HP, self.player_hp))
        self.ai_hp = max(0, min(MAX_HP, self.ai_hp))

    def _check_game_over(self) -> None:
        self.game_over = self.player_hp <= 0 or self.ai_hp <= 0

    def _print_intro(self) -> None:
        print("Potion Roulette - Terminal Edition")
        print("On your brewing turns, choose two cards for Potion A and two for Potion B.")
        print("The opponent picks one hidden potion to drink. The other returns to the brewer.")
        print("You can always see your cards and the AI's remaining cards before choosing.")
        if self.seed is not None:
            print(f"Seed: {self.seed}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Play Potion Roulette in the terminal.")
    parser.add_argument("--seed", type=int, default=None, help="Set a seed for repeatable matches.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    game = PotionRouletteTerminal(seed=args.seed)
    return game.play()


if _name_ == "_main_":
    raise SystemExit(main())