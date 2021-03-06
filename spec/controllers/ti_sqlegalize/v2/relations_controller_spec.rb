# encoding: utf-8
require 'rails_helper'

describe TiSqlegalize::V2::RelationsController do

  before(:each) do
    mock_domains
    mock_schemas
  end

  let!(:query) { Fabricate(:finished_query) }

  context "without and authenticated user" do

    it "requires authentication" do
      get_api :show_by_query, query_id: query.id
      expect(response.status).to eq(401)
    end

  end

  context "with an authenticated user" do

    let(:user) { Fabricate(:user_market) }

    before(:each) do
      sign_in user
    end

    it "complains on unknown resource" do
      get_api :show_by_query, query_id: "not_a_query"
      expect(response.status).to eq(404)
      expect(jsonapi_error).to eq("not found")
    end

    it "complains on invalid parameter" do
      get_api :show_by_query, query_id: [1,2,"not_an_id"]
      expect(response.status).to eq(400)
      expect(jsonapi_error).to eq("invalid parameters")
    end

    it "complains when not ready" do
      unfinished_query = Fabricate(:created_query)

      get_api :show_by_query, query_id: unfinished_query.id
      expect(response.status).to eq(409)
      expect(jsonapi_error).to eq("conflict")
    end

    it "fetches a query result" do
      get_api :show_by_query, query_id: query.id
      expect(response.status).to eq(200)
      expect(jsonapi_type).to eq('relation')
      expect(jsonapi_id).to eq(query.id)
      expect(jsonapi_data).to reside_at(v2_query_result_url(query.id))
      expect(jsonapi_attr 'sql').to eq(query.statement)
      expect(jsonapi_attr 'heading').to eq(['a'])

      expect(jsonapi_rel 'heading_a').to \
        relate_to(v2_query_result_heading_url(query.id, 'a'))

      expect(jsonapi_rel 'heading_a').to \
        be_identified_by('domain' => 'IATA_CITY')

      expect(jsonapi_rel 'body').to \
        relate_to(v2_query_result_body_url(query.id))

      iata_city = jsonapi_inc 'domain', 'IATA_CITY'
      expect(jsonapi_attr 'name', iata_city).to eq('IATA_CITY')
    end

    it "complains on unknown domain" do
      get_api :index_by_domain, domain_id: "not_a_domain"
      expect(response.status).to eq(404)
      expect(jsonapi_error).to eq("not found")
    end

    it "complains on invalid domain parameter" do
      get_api :index_by_domain, domain_id: [1,2,"not_an_id"]
      expect(response.status).to eq(400)
      expect(jsonapi_error).to eq("invalid parameters")
    end

    it "fetches relations for a domain" do
      pending("Lookup of relations by domain not implemented")
      domain = Fabricate(:domain)

      get_api :index_by_domain, domain_id: domain.id
      expect(response.status).to eq(200)
      expect(jsonapi_root).to reside_at(v2_domain_relations_url(domain.id))
      expect(jsonapi_data).not_to be_empty
    end

    it "complains on unknown schema" do
      get_api :index_by_schema, schema_id: "not_a_schema"
      expect(response.status).to eq(404)
      expect(jsonapi_error).to eq("not found")
    end

    it "complains on invalid schema parameter" do
      get_api :index_by_schema, schema_id: [1,2,"not_an_id"]
      expect(response.status).to eq(400)
      expect(jsonapi_error).to eq("invalid parameters")
    end

    it "fetches relations for a schema" do
      schema = Fabricate(:schema)
      table = schema.tables.first

      get_api :index_by_schema, schema_id: schema.id
      expect(response.status).to eq(200)
      expect(jsonapi_root).to reside_at(v2_schema_relations_url(schema.id))
      expect(jsonapi_data).not_to be_empty

      r = jsonapi_data.first
      expect(jsonapi_type r).to eq('relation')
      expect(jsonapi_id r).to eq(table.id)
      expect(r).to \
        reside_at(v2_relation_url(table.id))
      expect(jsonapi_attr 'name', r).to eq('BOOKINGS_OND')
      expect(jsonapi_attr 'heading', r).to eq(['BOARD_CITY'])

      expect(jsonapi_rel 'heading_BOARD_CITY', r).to \
        relate_to(v2_relation_heading_url(table.id, 'BOARD_CITY'))

      expect(jsonapi_rel 'body', r).to \
        relate_to(v2_relation_body_url(table.id))
    end

    it "fetches a relation by self URL" do
      table = Fabricate(:table)

      get_api :show, id: table.id
      expect(response.status).to eq(200)
      expect(jsonapi_type).to eq('relation')
      expect(jsonapi_id).to eq(table.id)
      expect(jsonapi_data).to reside_at(v2_relation_url(table.id))
      expect(jsonapi_attr 'name').to eq(table.name)
      expect(jsonapi_attr 'heading').to eq(['BOARD_CITY'])

      expect(jsonapi_rel 'heading_BOARD_CITY').to \
        relate_to(v2_relation_heading_url(table.id, 'BOARD_CITY'))

      expect(jsonapi_rel 'heading_BOARD_CITY').to \
        be_identified_by('domain' => 'IATA_CITY')

      expect(jsonapi_rel 'body').to \
        relate_to(v2_relation_body_url(table.id))

      iata_city = jsonapi_inc 'domain', 'IATA_CITY'
      expect(jsonapi_attr 'name', iata_city).to eq('IATA_CITY')
    end

    context "with a user without schema access" do

      let(:user) { Fabricate(:user_hr) }

      it "compains for unknown schema" do
        schema = Fabricate(:schema)

        get_api :index_by_schema, schema_id: schema.id
        expect(response.status).to eq(404)
        expect(jsonapi_error).to eq("not found")
      end

      it "compains for unknown table" do
        table = Fabricate(:table)

        get_api :show, id: table.id
        expect(response.status).to eq(404)
        expect(jsonapi_error).to eq("not found")
      end
    end
  end
end
