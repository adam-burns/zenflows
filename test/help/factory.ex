defmodule ZenflowsTest.Help.Factory do
@moduledoc """
Defines shortcuts for DB testing.
"""

alias Zenflows.DB.Repo
alias Zenflows.{Restroom, VF}

defdelegate id(), to: Zenflows.DB.ID, as: :gen

@doc """
Returns the same string with a unique positive integer attached at
the end.
"""
@spec uniq(String.t()) :: String.t()
def uniq(str) do
	str <> "#{System.unique_integer([:positive])}"
end

@doc """
Returns the same string with a unique positive integer attached at
the end.
"""
@spec str(String.t()) :: String.t()
def str(s) do
	"#{s}#{System.unique_integer([:positive])}"
end

@doc """
Returns a list of string composed of one or ten items.  Each item is
generated by piping `str` to `uniq/1`
"""
def str_list(s, min \\ 1, max \\ 10) do
	max = Enum.random(1..max)
	Enum.map(min..max, fn _ -> str(s) end)
end

@doc """
Returns a list of string composed of one or ten items.  Each item is
generated by piping `str` to `uniq/1`
"""
@spec uniq_list(String.t()) :: list(String.t())
def uniq_list(str) do
	max = Enum.random(1..10)
	Enum.map(1..max, fn _ -> uniq(str) end)
end

@doc """
Returns a random integer between 0 (inclusive) and `max` (exclusive).
"""
@spec int() :: integer()
def int(max \\ 100) do
	ceil(float(max))
end

@doc """
Returns a random float of the from 0 (inclusive) and 1 (exclusive)
multiplied by `mul`.
"""
@spec float() :: float()
def float(mul \\ 100) do
	:rand.uniform() * mul
end

@doc "Returns a random boolean."
@spec bool() :: boolean()
def bool() do
	:rand.uniform() < 0.5
end

@doc "Returns a unique URI string."
@spec uri() :: String.t()
def uri() do
	uniq("schema://user@host:port/path")
end

@doc "Inserts a schema into the database with field overrides."
@spec insert!(atom(), %{required(atom()) => term()}) :: struct()
def insert!(name, attrs \\ %{}) do
	name |> build!(attrs) |> Repo.insert!()
end

@doc "Builds a schema with field overrides."
@spec build!(atom(), %{required(atom()) => term()}) :: struct()
def build!(name, attrs \\ %{}) do
	name |> build() |> struct!(attrs)
end

@doc """
Like `build!/2`, but returns just a map.
Useful for things like IDuration in the GraphQL spec.
"""
@spec build_map!(atom()) :: map()
def build_map!(name) do
	build!(name)
	|> Map.delete(:__struct__)
	|> Map.delete(:__meta__)
end

def build(:time_unit) do
	Enum.random(VF.TimeUnit.values())
end

def build(:iduration) do
	%{
		unit_type: build(:time_unit),
		numeric_duration: float(),
	}
end

def build(:unit) do
	%VF.Unit{
		label: uniq("some label"),
		symbol: uniq("some symbol"),
	}
end

def build(:imeasure) do
	%VF.Measure{
		has_unit: build(:unit),
		has_numerical_value: float(),
	}
end

def build(:spatial_thing) do
	%VF.SpatialThing{
		name: uniq("some name"),
		mappable_address: uniq("some mappable_address"),
		lat: float(),
		long: float(),
		alt: float(),
		note: uniq("some note"),
	}
end

def build(:action_id) do
	Enum.random(VF.Action.ID.values())
end

def build(:process_specification) do
	%VF.ProcessSpecification{
		name: uniq("some name"),
		note: uniq("some note"),
	}
end

def build(:resource_specification) do
	%VF.ResourceSpecification{
		name: uniq("some name"),
		resource_classified_as: uniq_list("some uri"),
		note: uniq("some note"),
		image: uri(),
		default_unit_of_effort: build(:unit),
		default_unit_of_resource: build(:unit),
	}
end

def build(:recipe_resource) do
	%VF.RecipeResource{
		name: uniq("some name"),
		unit_of_resource: build(:unit),
		unit_of_effort: build(:unit),
		resource_classified_as: uniq_list("some uri"),
		resource_conforms_to: build(:resource_specification),
		substitutable: bool(),
		note: uniq("some note"),
		image: uri(),
	}
end

def build(:recipe_process) do
	dur = build(:iduration)
	%VF.RecipeProcess{
		name: uniq("some name"),
		note: uniq("some note"),
		process_classified_as: uniq_list("some uri"),
		process_conforms_to: build(:process_specification),
		has_duration_unit_type: dur.unit_type,
		has_duration_numeric_duration: dur.numeric_duration,
	}
end

def build(:recipe_exchange) do
	%VF.RecipeExchange{
		name: uniq("some name"),
		note: uniq("some note"),
	}
end

def build(:recipe_flow) do
	resqty = build(:imeasure)
	effqty = build(:imeasure)
	%VF.RecipeFlow{
		action_id: build(:action_id),
		recipe_input_of: build(:recipe_process),
		recipe_output_of: build(:recipe_process),
		recipe_flow_resource: build(:recipe_resource),
		resource_quantity_has_unit: resqty.has_unit,
		resource_quantity_has_numerical_value: resqty.has_numerical_value,
		effort_quantity_has_unit: effqty.has_unit,
		effort_quantity_has_numerical_value: effqty.has_numerical_value,
		recipe_clause_of: build(:recipe_exchange),
		note: uniq("some note"),
	}
end

def build(:person) do
	%VF.Person{
		type: :per,
		name: uniq("some name"),
		image: uri(),
		note: uniq("some note"),
		primary_location: build(:spatial_thing),
		user: uniq("some user"),
		email: "#{uniq("user")}@example.com",
		pubkeys: Base.url_encode64(Jason.encode!(%{a: 1, b: 2, c: 3})),
	}
end

def build(:organization) do
	%VF.Organization{
		type: :org,
		name: uniq("some name"),
		image: uri(),
		classified_as: uniq_list("some uri"),
		note: uniq("some note"),
		primary_location: build(:spatial_thing),
	}
end

def build(:agent) do
	type = if(bool(), do: :person, else: :person)
	struct(VF.Agent, build_map!(type))
end

def build(:role_behavior) do
	%VF.RoleBehavior{
		name: uniq("some name"),
		note: uniq("some note"),
	}
end

def build(:agent_relationship_role) do
	%VF.AgentRelationshipRole{
		role_behavior: build(:role_behavior),
		role_label: uniq("some role label"),
		inverse_role_label: uniq("some role label"),
		note: uniq("some note"),
	}
end

def build(:agent_relationship) do
	%VF.AgentRelationship{
		subject: build(:agent),
		object: build(:agent),
		relationship: build(:agent_relationship_role),
		# in_scope_of:
		note: uniq("some note"),
	}
end

def build(:agreement) do
	%VF.Agreement{
		name: uniq("some name"),
		created: DateTime.utc_now(),
		note: uniq("some note"),
	}
end

def build(:scenario_definition) do
	dur = build(:iduration)
	%VF.ScenarioDefinition{
		name: uniq("some name"),
		note: uniq("some note"),
		has_duration_unit_type: dur.unit_type,
		has_duration_numeric_duration: dur.numeric_duration,
	}
end

def build(:scenario) do
	recurse? = bool()

	%VF.Scenario{
		name: uniq("some name"),
		note: uniq("some note"),
		has_beginning: DateTime.utc_now(),
		has_end: DateTime.utc_now(),
		defined_as: build(:scenario_definition),
		refinement_of: if(recurse?, do: build(:scenario)),
	}
end

def build(:plan) do
	%VF.Plan{
		name: uniq("some name"),
		created: DateTime.utc_now(),
		due: DateTime.utc_now(),
		note: uniq("some note"),
		refinement_of: build(:scenario),
	}
end

def build(:process) do
	%VF.Process{
		name: uniq("some name"),
		note: uniq("some note"),
		has_beginning: DateTime.utc_now(),
		has_end: DateTime.utc_now(),
		finished: bool(),
		classified_as: uniq_list("some uri"),
		based_on: build(:process_specification),
		# in_scope_of:
		planned_within: build(:plan),
		nested_in: build(:scenario),
	}
end

def build(:product_batch) do
	%VF.ProductBatch{
		batch_number: uniq("some batch number"),
		expiry_date: DateTime.utc_now(),
		production_date: DateTime.utc_now(),
	}
end

def build(:economic_resource) do
	recurse? = bool()
	qty = build(:imeasure)

	%VF.EconomicResource{
		name: uniq("some name"),
		note: uniq("some note"),
		image: uri(),
		tracking_identifier: uniq("some tracking identifier"),
		classified_as: uniq_list("some uri"),
		conforms_to: build(:resource_specification),
		accounting_quantity_has_unit: qty.has_unit,
		accounting_quantity_has_numerical_value: qty.has_numerical_value,
		onhand_quantity_has_unit: qty.has_unit,
		onhand_quantity_has_numerical_value: qty.has_numerical_value,
		primary_accountable: build(:agent),
		custodian: build(:agent),
		stage: build(:process_specification),
		state_id: build(:action_id),
		current_location: build(:spatial_thing),
		lot: build(:product_batch),
		contained_in: if(recurse?, do: build(:economic_resource)),
		unit_of_effort: build(:unit),
	}
end

def build(:economic_event) do
	%{}
end

def build(:appreciation) do
	%VF.Appreciation{
		appreciation_of: build(:economic_event),
		appreciation_with: build(:economic_event),
		note: uniq("some note"),
	}
end

def build(:intent) do
	agent_mutex? = bool()
	resqty = build(:imeasure)
	effqty = build(:imeasure)
	availqty = build(:imeasure)

	%VF.Intent{
		name: uniq("some name"),
		action_id: build(:action_id),
		provider: if(agent_mutex?, do: build(:agent)),
		receiver: unless(agent_mutex?, do: build(:agent)),
		input_of: build(:process),
		output_of: build(:process),
		resource_classified_as: uniq_list("some uri"),
		resource_conforms_to: build(:resource_specification),
		resource_inventoried_as: build(:economic_resource),
		resource_quantity_has_unit: resqty.has_unit,
		resource_quantity_has_numerical_value: resqty.has_numerical_value,
		effort_quantity_has_unit: effqty.has_unit,
		effort_quantity_has_numerical_value: effqty.has_numerical_value,
		available_quantity_has_unit: availqty.has_unit,
		available_quantity_has_numerical_value: availqty.has_numerical_value,
		at_location: build(:spatial_thing),
		has_beginning: DateTime.utc_now(),
		has_end: DateTime.utc_now(),
		has_point_in_time: DateTime.utc_now(),
		due: DateTime.utc_now(),
		finished: bool(),
		image: uri(),
		note: uniq("some note"),
		# in_scope_of:
		agreed_in: uniq("some uri"),
	}
end

def build(:commitment) do
	datetime_mutex? = bool()
	resource_mutex? = bool()
	resqty = build(:imeasure)
	effqty = build(:imeasure)

	%VF.Commitment{
		action_id: build(:action_id),
		provider: build(:agent),
		receiver: build(:agent),
		input_of: build(:process),
		output_of: build(:process),
		resource_classified_as: uniq_list("some uri"),
		resource_conforms_to: if(resource_mutex?, do: build(:resource_specification)),
		resource_inventoried_as: unless(resource_mutex?, do: build(:economic_resource)),
		resource_quantity_has_unit: resqty.has_unit,
		resource_quantity_has_numerical_value: resqty.has_numerical_value,
		effort_quantity_has_unit: effqty.has_unit,
		effort_quantity_has_numerical_value: effqty.has_numerical_value,
		has_beginning: if(datetime_mutex?, do: DateTime.utc_now()),
		has_end: if(datetime_mutex?, do: DateTime.utc_now()),
		has_point_in_time: unless(datetime_mutex?, do: DateTime.utc_now()),
		due: DateTime.utc_now(),
		finished: bool(),
		note: uniq("some note"),
		# in_scope_of:
		agreed_in: uniq("some uri"),
		independent_demand_of: build(:plan),
		at_location: build(:spatial_thing),
		clause_of: build(:agreement),
	}
end

def build(:fulfillment) do
	resqty = build(:imeasure)
	effqty = build(:imeasure)

	%VF.Fulfillment{
		note: uniq("some note"),
		fulfilled_by: build(:economic_event),
		fulfills: build(:commitment),
		resource_quantity_has_unit: resqty.has_unit,
		resource_quantity_has_numerical_value: resqty.has_numerical_value,
		effort_quantity_has_unit: effqty.has_unit,
		effort_quantity_has_numerical_value: effqty.has_numerical_value,
	}
end

def build(:event_or_commitment) do
	mutex? = bool()

	%VF.EventOrCommitment{
		event: if(mutex?, do: build(:economic_event)),
		commitment: unless(mutex?, do: build(:commitment)),
	}
end

def build(:satisfaction) do
	resqty = build(:imeasure)
	effqty = build(:imeasure)

	%VF.Satisfaction{
		satisfied_by: build(:event_or_commitment),
		satisfies: build(:intent),
		resource_quantity_has_unit: resqty.has_unit,
		resource_quantity_has_numerical_value: resqty.has_numerical_value,
		effort_quantity_has_unit: effqty.has_unit,
		effort_quantity_has_numerical_value: effqty.has_numerical_value,
		note: uniq("some note"),
	}
end

def build(:claim) do
	resqty = build(:imeasure)
	effqty = build(:imeasure)

	%VF.Claim{
		action_id: build(:action_id),
		provider: build(:agent),
		receiver: build(:agent),
		resource_classified_as: uniq_list("some uri"),
		resource_conforms_to: build(:resource_specification),
		resource_quantity_has_unit: resqty.has_unit,
		resource_quantity_has_numerical_value: resqty.has_numerical_value,
		effort_quantity_has_unit: effqty.has_unit,
		effort_quantity_has_numerical_value: effqty.has_numerical_value,
		triggered_by: if(bool(), do: build(:economic_event), else: nil),
		due: DateTime.utc_now(),
		created: DateTime.utc_now(),
		finished: bool(),
		agreed_in: uniq("some uri"),
		note: uniq("some note"),
		# in_scope_of:
	}
end

def build(:settlement) do
	resqty = build(:imeasure)
	effqty = build(:imeasure)

	%VF.Settlement{
		settled_by: build(:economic_event),
		settles: build(:claim),
		resource_quantity_has_unit: resqty.has_unit,
		resource_quantity_has_numerical_value: resqty.has_numerical_value,
		effort_quantity_has_unit: effqty.has_unit,
		effort_quantity_has_numerical_value: effqty.has_numerical_value,
		note: uniq("some note"),
	}
end

def build(:proposal) do
	%VF.Proposal{
		name: uniq("some name"),
		has_beginning: DateTime.utc_now(),
		has_end: DateTime.utc_now(),
		unit_based: bool(),
		note: uniq("some note"),
		eligible_location: build(:spatial_thing),
	}
end

def build(:proposed_intent) do
	%VF.ProposedIntent{
		reciprocal: bool(),
		publishes: build(:intent),
		published_in: build(:proposal),
	}
end

def build(:proposed_to) do
	%VF.ProposedTo{
		proposed_to: build(:agent),
		proposed: build(:proposal),
	}
end
end
