defmodule EdgeBuilder.Controllers.CharacterControllerTest do
  use EdgeBuilder.ControllerTest

  alias Factories.CharacterFactory
  alias Factories.UserFactory
  alias EdgeBuilder.Models.Character
  alias EdgeBuilder.Models.Talent
  alias EdgeBuilder.Models.Attack
  alias EdgeBuilder.Models.BaseSkill
  alias EdgeBuilder.Models.CharacterSkill
  alias EdgeBuilder.Repo
  alias Helpers.FlokiExt
  import Ecto.Query, only: [from: 2]

  describe "new" do
    it "renders the character edit form for a new character" do
      conn = authenticated_request(UserFactory.default_user, :get, "/characters/new")

      assert conn.status == 200
      assert String.contains?(conn.resp_body, "New Character")
    end

    it "requires authentication" do
      conn = request(:get, "/characters/new")

      assert requires_authentication?(conn)
    end
  end

  describe "create" do
    it "creates a character" do
      base_skills = BaseSkill.all
        |> Enum.reject(&(&1.name == "Athletics"))
        |> Enum.with_index
        |> Enum.map(fn {skill, index} ->
            {index, %{"base_skill_id" => skill.id, "rank" => "0"}}
          end)
        |> Enum.into(%{})

      skills_with_user_edit = base_skills
        |> Map.put("Athletics", %{"base_skill_id" => BaseSkill.by_name("Athletics").id, "rank" => "3", "is_career" => "on"})

      authenticated_request(UserFactory.default_user, :post, "/characters", %{
        "character" => %{
          "name" => "Greedo",
          "species" => "Rodian",
          "career" => "Bounty Hunter",
          "credits" => "3000",
          "defense_melee" => "1",
          "defense_ranged" => "2",
          "encumbrance" => "5 / 8",
          "motivation" => "Kill some dudes",
          "obligation" => "(10 pts) Has to kill some dudes",
          "soak" => "3",
          "specializations" => "Hired Gun",
          "strain_current" => "4",
          "strain_threshold" => "5",
          "wounds_current" => "",
          "wounds_threshold" => "7",
          "xp_available" => "100",
          "xp_total" => "200",
          "background" => "A regular Rodian, you know",
          "description" => "Green",
          "other_notes" => "Not the best",
        },
        "attacks" => %{
          "0" => %{"critical" => "3", "damage" => "4", "range" => "Short", "base_skill_id" => BaseSkill.by_name("Ranged: Light").id, "specials" => "Stun Setting", "weapon_name" => "Holdout Blaster"},
          "1" => %{"id" => "", "critical" => "5", "damage" => "+1", "range" => "Engaged", "base_skill_id" => BaseSkill.by_name("Brawl").id, "specials" => "", "weapon_name" => "Claws"}
        },
        "skills" => skills_with_user_edit,
        "talents" => %{
          "0" => %{"book_and_page" => "EotE p25", "description" => "Draw as incidental", "name" => "Quick Draw"},
          "1" => %{"book_and_page" => "DC p200", "description" => "Upgrade all checks by one", "name" => "Adversary 1"}
        },
      })

      character = Repo.all(Character) |> Enum.at(0)

      assert character.user_id == UserFactory.default_user.id
      assert character.name == "Greedo"
      assert character.species == "Rodian"
      assert character.career == "Bounty Hunter"
      assert character.credits == 3000
      assert character.defense_melee == 1
      assert character.defense_ranged == 2
      assert character.encumbrance == "5 / 8"
      assert character.motivation == "Kill some dudes"
      assert character.obligation == "(10 pts) Has to kill some dudes"
      assert character.soak == 3
      assert character.specializations == "Hired Gun"
      assert character.strain_current == 4
      assert character.strain_threshold == 5
      assert is_nil(character.wounds_current)
      assert character.wounds_threshold == 7
      assert character.xp_available == 100
      assert character.xp_total == 200
      assert character.background == "A regular Rodian, you know"
      assert character.description == "Green"
      assert character.other_notes == "Not the best"

      [first_attack, second_attack] = Attack.for_character(character.id)

      assert first_attack.critical == "3"
      assert first_attack.damage == "4"
      assert first_attack.range == "Short"
      assert first_attack.base_skill_id == BaseSkill.by_name("Ranged: Light").id
      assert first_attack.specials == "Stun Setting"
      assert first_attack.weapon_name == "Holdout Blaster"
 
      assert second_attack.critical == "5"
      assert second_attack.damage == "+1"
      assert second_attack.range == "Engaged"
      assert second_attack.base_skill_id == BaseSkill.by_name("Brawl").id
      assert second_attack.specials == nil
      assert second_attack.weapon_name == "Claws"

      [first_talent, second_talent] = Talent.for_character(character.id)

      assert first_talent.book_and_page == "EotE p25"
      assert first_talent.description == "Draw as incidental"
      assert first_talent.name == "Quick Draw"

      assert second_talent.book_and_page == "DC p200"
      assert second_talent.description == "Upgrade all checks by one"
      assert second_talent.name == "Adversary 1"
      
      [character_skill] = CharacterSkill.for_character(character.id)

      assert character_skill.base_skill_id == BaseSkill.by_name("Athletics").id
      assert character_skill.is_career
      assert character_skill.rank == 3
    end

    it "redirects to the character show page" do
      params = CharacterFactory.default_parameters
      conn = authenticated_request(UserFactory.default_user, :post, "/characters", %{"character" => params})

      character = Repo.one!(from c in Character, where: c.name == ^params["name"])

      assert is_redirect_to?(conn, EdgeBuilder.Router.Helpers.character_path(conn, :show, character.id))
    end

    it "re-renders the new character page when there are errors" do
      conn = authenticated_request(UserFactory.default_user, :post, "/characters", %{
        "character" => %{
          "species" => "Rodian",
          "career" => "Bounty Hunter"
        },
        "skills" => %{"0" => %{"base_skill_id" => BaseSkill.by_name("Athletics").id, "rank" => "3", "is_career" => "on"}}
      })

      assert FlokiExt.element(conn, ".alert-danger") |> FlokiExt.text == "Name can't be blank"
      assert FlokiExt.element(conn, "[data-skill=Athletics]") |> FlokiExt.attribute("value") == "3"
      assert !is_nil(FlokiExt.element(conn, ".attack-first-row"))
      assert !is_nil(FlokiExt.element(conn, ".talent-row"))
    end

    it "requires authentication" do
      conn = request(:post, "/characters")

      assert requires_authentication?(conn)
    end
  end

  describe "show" do
    it "displays the character information" do
      character = CharacterFactory.create_character

      conn = request(:get, "/characters/#{character.id}")

      assert conn.status == 200
      assert String.contains?(conn.resp_body, character.name)
    end

    it "displays edit and delete buttons when viewed by the owner" do
      character = CharacterFactory.create_character(user_id: UserFactory.default_user.id)

      conn = authenticated_request(UserFactory.default_user, :get, "/characters/#{character.id}")

      assert String.contains?(conn.resp_body, "Edit")
    end
  end

  describe "index" do
    it "displays a link to create a new character" do
      conn = authenticated_request(UserFactory.default_user, :get, "/characters")

      assert conn.status == 200
      assert String.contains?(conn.resp_body, EdgeBuilder.Router.Helpers.character_path(conn, :index))
    end

    it "displays links for each character" do
      user = UserFactory.default_user

      characters = [
        CharacterFactory.create_character(name: "Frank", user_id: user.id),
        CharacterFactory.create_character(name: "Boba Fett", user_id: user.id)
      ]

      conn = authenticated_request(UserFactory.default_user, :get, "/characters")

      for character <- characters do
        assert String.contains?(conn.resp_body, character.name)
        assert String.contains?(conn.resp_body, EdgeBuilder.Router.Helpers.character_path(conn, :show, character.id))
      end
    end

    it "displays characters in order of last updated" do
      user = UserFactory.default_user

      updated_character = CharacterFactory.create_character(name: "Frank", user_id: user.id)
      second_character = CharacterFactory.create_character(name: "Boba Fett", user_id: user.id)

      :timer.sleep(1000)
      updated_character = Character.changeset(updated_character, user.id, %{"name" => "Mike"}) |> Repo.update

      conn = authenticated_request(user, :get, "/characters")
      {first_position, _} = :binary.match(conn.resp_body, updated_character.name)
      {second_position, _} = :binary.match(conn.resp_body, second_character.name)

      assert first_position < second_position
    end

    it "displays links for only characters owned by the current user" do
      user = UserFactory.default_user
      other = UserFactory.create_user

      character = CharacterFactory.create_character(name: "Frank", user_id: other.id)

      conn = authenticated_request(user, :get, "/characters")

      assert !String.contains?(conn.resp_body, character.name)
    end

    it "requires authentication" do
      conn = request(:get, "/characters")

      assert requires_authentication?(conn)
    end
  end

  describe "edit" do
    it "renders the character edit form" do
      character = CharacterFactory.create_character(user_id: UserFactory.default_user.id)

      character_skill = %CharacterSkill{
        base_skill_id: BaseSkill.by_name("Athletics").id,
        rank: 4,
        character_id: character.id
      } |> Repo.insert

      talent = %Talent{
        name: "Quick Draw",
        character_id: character.id
      } |> Repo.insert

      attack = %Attack{
        weapon_name: "Holdout Blaster",
        character_id: character.id
      } |> Repo.insert

      conn = authenticated_request(UserFactory.default_user, :get, "/characters/#{character.id}/edit")

      assert conn.status == 200
      assert String.contains?(conn.resp_body, character.name)
      assert String.contains?(conn.resp_body, character_skill.rank |> to_string)
      assert String.contains?(conn.resp_body, talent.name)
      assert String.contains?(conn.resp_body, attack.weapon_name)
    end

    it "requires authentication" do
      conn = request(:get, "/characters/123/edit")

      assert requires_authentication?(conn)
    end

    it "requires the current user to match the owning user" do
      owner = UserFactory.default_user
      other = UserFactory.create_user(username: "other")
      character = CharacterFactory.create_character(user_id: owner.id)

      conn = authenticated_request(other, :get, "/characters/#{character.id}/edit")

      assert is_redirect_to?(conn, "/")
    end
  end

  describe "update" do
    it "updates the character's basic attributes" do
      character = CharacterFactory.create_character(name: "asdasd", species: "gogogo")

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{"name" => "Do'mesh", "species" => "Twi'lek"}})

      character = Repo.get(Character, character.id)

      assert character.name == "Do'mesh"
      assert character.species == "Twi'lek"
    end

    it "redirects to the character show page" do
      character = CharacterFactory.create_character

      conn = authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{"name" => "Do'mesh", "species" => "Twi'lek"}})

      assert conn.status == 302
      assert is_redirect_to?(conn, EdgeBuilder.Router.Helpers.character_path(conn, :show, character.id))
    end

    it "updates the character's optional attributes" do
      character = CharacterFactory.create_character(
        xp_total: 50,
        xp_available: 10,
        description: "A slow shooter"
      )

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{
        "xp_total" => "60",
        "xp_available" => "",
        "description" =>  "tbd"
      }})

      character = Repo.get(Character, character.id)

      assert character.xp_total == 60
      assert is_nil(character.xp_available)
      assert character.description == "tbd"
      assert is_nil(character.other_notes)
    end

    it "updates the character's prior talents" do
      character = CharacterFactory.create_character

      talent = %Talent{
        name: "Quick Draw",
        book_and_page: "EotE Core p145",
        description: "Draws a gun quickly",
        character_id: character.id
      } |> Repo.insert

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}, "talents" => %{
        "0" => %{"book_and_page" => "DC p43", "description" => "Do stuff", "id" => talent.id, "name" => "Awesome Guy"}
      }})

      [talent] = Talent.for_character(character.id)

      assert talent.name == "Awesome Guy"
      assert talent.description == "Do stuff"
      assert talent.book_and_page == "DC p43"
    end

    it "creates new talents for the character" do
      character = CharacterFactory.create_character

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}, "talents" => %{
        "0" => %{"book_and_page" => "DC p43", "description" => "Do stuff", "name" => "Awesome Guy"}
      }})

      [talent] = Talent.for_character(character.id)

      assert talent.name == "Awesome Guy"
      assert talent.description == "Do stuff"
      assert talent.book_and_page == "DC p43"
    end

    it "filters out empty talents from the request" do
      character = CharacterFactory.create_character

      talent = %Talent{
        name: "Quick Draw",
        book_and_page: "EotE Core p145",
        description: "Draws a gun quickly",
        character_id: character.id
      } |> Repo.insert

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}, "talents" => %{
        "0" => %{"book_and_page" => "", "description" => "", "name" => ""},
        "1" => %{"book_and_page" => "", "description" => "", "name" => "", "id" => talent.id}
      }})

      assert [] == Talent.for_character(character.id)
    end

    it "deletes any talents for that character that were not specified in the update" do
      character = CharacterFactory.create_character

      %Talent{
        name: "Quick Draw",
        book_and_page: "EotE Core p145",
        description: "Draws a gun quickly",
        character_id: character.id
      } |> Repo.insert

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}})

      talents = Talent.for_character(character.id)

      assert Enum.count(talents) == 0
      assert Repo.all(Talent) |> Enum.count == 0
    end

    it "updates the character's prior attacks" do
      character = CharacterFactory.create_character

      attack = %Attack{
        weapon_name: "Holdout Blaster",
        range: "Short",
        character_id: character.id
      } |> Repo.insert

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}, "attacks" => %{
        "0" => %{"weapon_name" => "Claws", "range" => "Engaged", "id" => attack.id}
      }})

      [attack] = Attack.for_character(character.id)

      assert attack.weapon_name == "Claws"
      assert attack.range == "Engaged"
    end

    it "creates new attacks for the character" do
      character = CharacterFactory.create_character

      base_skill = Repo.all(BaseSkill) |> Enum.at(0)

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}, "attacks" => %{
        "0" => %{"weapon_name" => "Claws", "range" => "Engaged", "base_skill_id" => base_skill.id}
      }})

      [attack] = Attack.for_character(character.id)

      assert attack.weapon_name == "Claws"
      assert attack.range == "Engaged"
      assert attack.base_skill_id == base_skill.id
    end

    it "deletes any attacks for that character that were not specified in the update" do
      character = CharacterFactory.create_character

      %Attack{
        weapon_name: "Holdout Blaster",
        range: "Short",
        character_id: character.id
      } |> Repo.insert

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}})

      attacks = Attack.for_character(character.id)

      assert Enum.count(attacks) == 0
      assert Repo.all(Attack) |> Enum.count == 0
    end

    it "creates new skills when they differ from default values" do
      character = CharacterFactory.create_character

      base_skill = BaseSkill.by_name("Athletics")

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}, "skills" => %{"0" => %{"base_skill_id" => base_skill.id, "rank" => 1, "is_career" => "on"}}})

      [character_skill] = CharacterSkill.for_character(character.id)

      assert character_skill.rank == 1
      assert character_skill.is_career
      assert character_skill.base_skill_id == base_skill.id
    end

    it "does not create new skills for skills that are not persisted and that do not differ from defaults" do
      character = CharacterFactory.create_character

      base_skill = BaseSkill.by_name("Athletics")

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}, "skills" => %{"0" => %{"base_skill_id" => base_skill.id, "rank" => 0}}})

      assert Enum.count(CharacterSkill.for_character(character.id)) == 0
    end

    it "deletes previously-saved skills that are set back to the default" do
      character = CharacterFactory.create_character

      base_skill = BaseSkill.by_name("Athletics")

      original_character_skill = %CharacterSkill{
        base_skill_id: base_skill.id,
        character_id: character.id,
        rank: 5
      } |> Repo.insert

      authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{"character" => %{}, "skills" => %{"0" => %{"base_skill_id" => base_skill.id, "rank" => 0, "id" => original_character_skill.id}}})

      assert [] == CharacterSkill.for_character(character.id)
    end

    it "re-renders the edit character page when there are errors" do
      character = CharacterFactory.create_character

      base_skill = BaseSkill.by_name("Astrogation")

      %CharacterSkill{
        base_skill_id: base_skill.id,
        character_id: character.id,
        rank: 5
      } |> Repo.insert

      conn = authenticated_request(UserFactory.default_user, :put, "/characters/#{character.id}", %{
        "character" => %{
          "name" => "",
          "species" => "Rodian",
          "career" => "Bounty Hunter"
        },
        "skills" => %{"0" => %{"base_skill_id" => BaseSkill.by_name("Athletics").id, "rank" => "3", "is_career" => "on"}}
      })

      assert FlokiExt.element(conn, ".alert-danger") |> FlokiExt.text == "Name can't be blank"
      assert FlokiExt.element(conn, "[data-skill=Athletics]") |> FlokiExt.attribute("value") == "3"
      assert !is_nil(FlokiExt.element(conn, ".attack-first-row"))
      assert !is_nil(FlokiExt.element(conn, ".talent-row"))
    end

    it "requires authentication" do
      conn = request(:put, "/characters/123")

      assert requires_authentication?(conn)
    end

    it "requires the current user to match the owning user" do
      owner = UserFactory.default_user
      other = UserFactory.create_user(username: "other")
      character = CharacterFactory.create_character(user_id: owner.id)

      conn = authenticated_request(other, :put, "/characters/#{character.id}", %{"character" => %{}})

      assert is_redirect_to?(conn, "/")
    end
  end

  describe "delete" do
    it "deletes a character and all associated records" do
      character = CharacterFactory.create_character

      base_skill = BaseSkill.by_name("Astrogation")

      %CharacterSkill{
        base_skill_id: base_skill.id,
        character_id: character.id,
        rank: 5
      } |> Repo.insert

      authenticated_request(UserFactory.default_user, :delete, "/characters/#{character.id}")

      assert is_nil(Repo.get(Character, character.id))
      assert is_nil(Repo.one(from cs in CharacterSkill, where: cs.id == ^(character.id)))
    end

    it "requires authentication" do
      conn = request(:delete, "/characters/123")

      assert requires_authentication?(conn)
    end

    it "requires the current user to match the owning user" do
      owner = UserFactory.default_user
      other = UserFactory.create_user(username: "other")
      character = CharacterFactory.create_character(user_id: owner.id)

      conn = authenticated_request(other, :delete, "/characters/#{character.id}")

      assert is_redirect_to?(conn, "/")
    end
  end
end
