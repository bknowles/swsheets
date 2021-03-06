defmodule EdgeBuilder.Models.BaseSkill do
  use EdgeBuilder.Model

  schema "base_skills" do
    field :name, :string
    field :characteristic, :string
    field :skill_position, :integer
    field :is_attack_skill, :boolean, default: false
  end

  def all do
    Repo.all(
      from bs in __MODULE__,
        order_by: :skill_position
    )
  end

  def by_name(name) do
    Repo.one(
      from bs in __MODULE__,
        where: bs.name == ^name
    )
  end

  def attack_skills do
    Repo.all(
      from bs in __MODULE__,
        where: bs.is_attack_skill == true,
        order_by: :skill_position
    )
  end
end
