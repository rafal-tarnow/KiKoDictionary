import pytest

BASE = "/api/sentences"


def add(client, headers, text: str) -> dict:
    response = client.post(
        f"{BASE}/",
        json={"original_text": text, "translated_text": f"{text} (en)", "source_language": "pl", "target_language": "en"},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    return response.json()


def my_texts(client, headers, page: int = 1, per_page: int = 100) -> list[str]:
    response = client.get(f"{BASE}/me", params={"page": page, "per_page": per_page}, headers=headers)
    assert response.status_code == 200, response.text
    return [s["original_text"] for s in response.json()["data"]]


@pytest.fixture
def five(client, user_a) -> dict[str, int]:
    """Dodane w kolejności A..E, więc na liście (najnowsze na górze): E D C B A."""
    return {text: add(client, user_a, text)["id"] for text in "ABCDE"}


class TestNewSentences:
    def test_new_sentence_lands_at_the_top(self, client, user_a, five):
        assert my_texts(client, user_a) == list("EDCBA")

        add(client, user_a, "F")

        assert my_texts(client, user_a)[0] == "F"

    def test_response_contains_position(self, client, user_a):
        sentence = add(client, user_a, "A")

        assert isinstance(sentence["position"], float)

    def test_cloned_community_sentence_lands_at_the_top(self, client, user_a, user_b, five):
        foreign = add(client, user_b, "Foreign")

        response = client.post(f"{BASE}/{foreign['id']}/clone", headers=user_a)

        assert response.status_code == 201
        assert my_texts(client, user_a)[0] == "Foreign"


class TestDragAndDrop:
    def reorder(self, client, headers, sentence_id, **body):
        return client.post(f"{BASE}/{sentence_id}/reorder", json=body, headers=headers)

    def test_move_between_two_sentences(self, client, user_a, five):
        # E D C B A -> przenosimy A między E i D
        response = self.reorder(client, user_a, five["A"], prev_id=five["E"], next_id=five["D"])

        assert response.status_code == 200
        assert my_texts(client, user_a) == list("EADCB")

    def test_move_to_first_slot(self, client, user_a, five):
        self.reorder(client, user_a, five["C"], next_id=five["E"])

        assert my_texts(client, user_a) == list("CEDBA")

    def test_move_to_last_slot(self, client, user_a, five):
        self.reorder(client, user_a, five["E"], prev_id=five["A"])

        assert my_texts(client, user_a) == list("DCBAE")

    def test_drop_at_top_of_second_page_stays_on_second_page(self, client, user_a, five):
        # per_page=2: [E D] [C B] [A] - klient na stronie 2 widzi tylko C i B.
        # Upuszczenie A na górze strony 2 (prev=None, next=C) ma dać [E D] [A C] [B].
        self.reorder(client, user_a, five["A"], next_id=five["C"])

        assert my_texts(client, user_a, page=1, per_page=2) == ["E", "D"]
        assert my_texts(client, user_a, page=2, per_page=2) == ["A", "C"]

    def test_many_moves_into_the_same_gap_keep_order(self, client, user_a, five):
        # Każde przesunięcie połowi przerwę - po kilkudziesięciu iteracjach wymagane przenumerowanie
        for i in range(80):
            moving = five["A"] if i % 2 == 0 else five["B"]
            self.reorder(client, user_a, moving, prev_id=five["E"])

        texts = my_texts(client, user_a)
        assert texts[0] == "E" and texts[-1] == "C"
        positions = [s["position"] for s in client.get(f"{BASE}/me", headers=user_a).json()["data"]]
        assert positions == sorted(positions) and len(set(positions)) == len(positions)

    def test_self_as_neighbour_is_rejected(self, client, user_a, five):
        assert self.reorder(client, user_a, five["A"], prev_id=five["A"]).status_code == 400

    def test_unknown_neighbour_is_rejected(self, client, user_a, five):
        assert self.reorder(client, user_a, five["A"], prev_id=999).status_code == 400

    def test_unknown_fields_are_rejected(self, client, user_a, five):
        assert self.reorder(client, user_a, five["A"], position=1).status_code == 422


class TestMoveToTopAndBottom:
    def test_move_to_top_from_last_page(self, client, user_a, five):
        response = client.post(f"{BASE}/{five['A']}/move-to-top", headers=user_a)

        assert response.status_code == 200
        assert my_texts(client, user_a, page=1, per_page=2) == ["A", "E"]

    def test_move_to_bottom_from_first_page(self, client, user_a, five):
        response = client.post(f"{BASE}/{five['E']}/move-to-bottom", headers=user_a)

        assert response.status_code == 200
        assert my_texts(client, user_a, page=3, per_page=2) == ["E"]

    def test_moving_first_to_top_is_a_no_op(self, client, user_a, five):
        before = client.get(f"{BASE}/me", headers=user_a).json()["data"]

        client.post(f"{BASE}/{five['E']}/move-to-top", headers=user_a)

        assert client.get(f"{BASE}/me", headers=user_a).json()["data"] == before

    def test_single_sentence_can_be_moved(self, client, user_a):
        only = add(client, user_a, "Only")

        assert client.post(f"{BASE}/{only['id']}/move-to-top", headers=user_a).status_code == 200
        assert client.post(f"{BASE}/{only['id']}/move-to-bottom", headers=user_a).status_code == 200


class TestIsolationBetweenUsers:
    def test_orders_are_independent(self, client, user_a, user_b, five):
        add(client, user_b, "X")
        add(client, user_b, "Y")

        client.post(f"{BASE}/{five['A']}/move-to-top", headers=user_a)

        assert my_texts(client, user_b) == ["Y", "X"]

    @pytest.mark.parametrize("action", ["move-to-top", "move-to-bottom"])
    def test_foreign_sentence_cannot_be_moved(self, client, user_a, user_b, five, action):
        assert client.post(f"{BASE}/{five['A']}/{action}", headers=user_b).status_code == 404

    def test_foreign_sentence_cannot_be_reordered(self, client, user_a, user_b, five):
        response = client.post(f"{BASE}/{five['A']}/reorder", json={"next_id": five["B"]}, headers=user_b)

        assert response.status_code == 404

    def test_foreign_sentence_cannot_be_used_as_neighbour(self, client, user_a, user_b, five):
        foreign = add(client, user_b, "Foreign")

        response = client.post(f"{BASE}/{five['A']}/reorder", json={"prev_id": foreign["id"]}, headers=user_a)

        assert response.status_code == 400

    def test_requires_authentication(self, client, five):
        assert client.post(f"{BASE}/{five['A']}/move-to-top").status_code == 401


def test_community_is_still_sorted_by_creation_date(client, user_a, five):
    client.post(f"{BASE}/{five['A']}/move-to-top", headers=user_a)

    community = client.get(f"{BASE}/community", params={"per_page": 100}).json()["data"]

    assert [s["original_text"] for s in community] == list("EDCBA")
