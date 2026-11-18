export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      booking_status_history: {
        Row: {
          auth_user_id: string
          booking_id: string
          created_at: string
          id: number
          status: string
        }
        Insert: {
          auth_user_id: string
          booking_id: string
          created_at?: string
          id?: never
          status: string
        }
        Update: {
          auth_user_id?: string
          booking_id?: string
          created_at?: string
          id?: never
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "booking_status_history_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "booking_status_history_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
        ]
      }
      bookings: {
        Row: {
          address_snapshot: Json
          auth_user_id: string
          created_at: string
          id: string
          idempotency_key: string
          organization_id: string | null
          payment_status: string
          quote_id: string
          requested_at: string
          service: string
          slot_id: string | null
          status: string
        }
        Insert: {
          address_snapshot: Json
          auth_user_id: string
          created_at?: string
          id?: string
          idempotency_key: string
          organization_id?: string | null
          payment_status?: string
          quote_id: string
          requested_at: string
          service: string
          slot_id?: string | null
          status?: string
        }
        Update: {
          address_snapshot?: Json
          auth_user_id?: string
          created_at?: string
          id?: string
          idempotency_key?: string
          organization_id?: string | null
          payment_status?: string
          quote_id?: string
          requested_at?: string
          service?: string
          slot_id?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "bookings_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "bookings_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_quote_id_fkey"
            columns: ["quote_id"]
            isOneToOne: true
            referencedRelation: "quotes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_slot_id_fkey"
            columns: ["slot_id"]
            isOneToOne: false
            referencedRelation: "collection_slots"
            referencedColumns: ["id"]
          },
        ]
      }
      collection_slots: {
        Row: {
          active: boolean
          capacity: number
          coverage_id: string
          ends_at: string
          id: string
          starts_at: string
        }
        Insert: {
          active?: boolean
          capacity: number
          coverage_id: string
          ends_at: string
          id?: string
          starts_at: string
        }
        Update: {
          active?: boolean
          capacity?: number
          coverage_id?: string
          ends_at?: string
          id?: string
          starts_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "collection_slots_coverage_id_fkey"
            columns: ["coverage_id"]
            isOneToOne: false
            referencedRelation: "service_availability"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_accounts: {
        Row: {
          account_type: Database["public"]["Enums"]["customer_category"]
          auth_user_id: string
          created_at: string
          display_name: string
          status: string
          verification_status: Database["public"]["Enums"]["verification_state"]
        }
        Insert: {
          account_type: Database["public"]["Enums"]["customer_category"]
          auth_user_id: string
          created_at?: string
          display_name: string
          status?: string
          verification_status?: Database["public"]["Enums"]["verification_state"]
        }
        Update: {
          account_type?: Database["public"]["Enums"]["customer_category"]
          auth_user_id?: string
          created_at?: string
          display_name?: string
          status?: string
          verification_status?: Database["public"]["Enums"]["verification_state"]
        }
        Relationships: []
      }
      customer_addresses: {
        Row: {
          address_text: string
          auth_user_id: string
          coverage_id: string | null
          coverage_verified: boolean
          created_at: string
          id: string
          label: string
          organization_id: string | null
        }
        Insert: {
          address_text: string
          auth_user_id: string
          coverage_id?: string | null
          coverage_verified?: boolean
          created_at?: string
          id?: string
          label: string
          organization_id?: string | null
        }
        Update: {
          address_text?: string
          auth_user_id?: string
          coverage_id?: string | null
          coverage_verified?: boolean
          created_at?: string
          id?: string
          label?: string
          organization_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "customer_addresses_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "customer_addresses_coverage_id_fkey"
            columns: ["coverage_id"]
            isOneToOne: false
            referencedRelation: "service_availability"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_addresses_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_notifications: {
        Row: {
          auth_user_id: string
          body: string
          created_at: string
          id: string
        }
        Insert: {
          auth_user_id: string
          body: string
          created_at?: string
          id?: string
        }
        Update: {
          auth_user_id?: string
          body?: string
          created_at?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_notifications_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
        ]
      }
      organization_members: {
        Row: {
          active: boolean
          auth_user_id: string
          can_book: boolean
          organization_id: string
        }
        Insert: {
          active?: boolean
          auth_user_id: string
          can_book?: boolean
          organization_id: string
        }
        Update: {
          active?: boolean
          auth_user_id?: string
          can_book?: boolean
          organization_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "organization_members_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "organization_members_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      organizations: {
        Row: {
          created_at: string
          id: string
          name: string
          owner_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          owner_id: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          owner_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "organizations_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
        ]
      }
      payment_orders: {
        Row: {
          amount_kobo: number
          auth_user_id: string
          authorization_url: string | null
          booking_id: string
          created_at: string
          currency: string
          id: string
          provider_reference: string
          provider_transaction_id: string | null
          status: string
          updated_at: string
        }
        Insert: {
          amount_kobo: number
          auth_user_id: string
          authorization_url?: string | null
          booking_id: string
          created_at?: string
          currency?: string
          id?: string
          provider_reference: string
          provider_transaction_id?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          amount_kobo?: number
          auth_user_id?: string
          authorization_url?: string | null
          booking_id?: string
          created_at?: string
          currency?: string
          id?: string
          provider_reference?: string
          provider_transaction_id?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_orders_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "payment_orders_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
        ]
      }
      pricing_rules: {
        Row: {
          active: boolean
          base_kobo: number
          category_id: string
          coverage_id: string
          id: string
          maximum_quantity: number
          minimum_quantity: number
          unit: string
          unit_kobo: number
          version: string
        }
        Insert: {
          active?: boolean
          base_kobo: number
          category_id: string
          coverage_id: string
          id?: string
          maximum_quantity: number
          minimum_quantity: number
          unit: string
          unit_kobo: number
          version: string
        }
        Update: {
          active?: boolean
          base_kobo?: number
          category_id?: string
          coverage_id?: string
          id?: string
          maximum_quantity?: number
          minimum_quantity?: number
          unit?: string
          unit_kobo?: number
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "pricing_rules_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "waste_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pricing_rules_coverage_id_fkey"
            columns: ["coverage_id"]
            isOneToOne: false
            referencedRelation: "service_availability"
            referencedColumns: ["id"]
          },
        ]
      }
      quotes: {
        Row: {
          address_id: string | null
          address_snapshot: Json | null
          amount_kobo: number
          auth_user_id: string
          category_id: string | null
          created_at: string
          currency: string
          destination_id: string | null
          expires_at: string
          id: string
          items: Json
          organization_id: string | null
          preparation_confirmed: boolean
          quantity: number | null
          rule_id: string | null
          slot_id: string | null
        }
        Insert: {
          address_id?: string | null
          address_snapshot?: Json | null
          amount_kobo: number
          auth_user_id: string
          category_id?: string | null
          created_at?: string
          currency?: string
          destination_id?: string | null
          expires_at: string
          id?: string
          items: Json
          organization_id?: string | null
          preparation_confirmed?: boolean
          quantity?: number | null
          rule_id?: string | null
          slot_id?: string | null
        }
        Update: {
          address_id?: string | null
          address_snapshot?: Json | null
          amount_kobo?: number
          auth_user_id?: string
          category_id?: string | null
          created_at?: string
          currency?: string
          destination_id?: string | null
          expires_at?: string
          id?: string
          items?: Json
          organization_id?: string | null
          preparation_confirmed?: boolean
          quantity?: number | null
          rule_id?: string | null
          slot_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quotes_address_id_fkey"
            columns: ["address_id"]
            isOneToOne: false
            referencedRelation: "customer_addresses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotes_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "quotes_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "waste_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotes_destination_id_fkey"
            columns: ["destination_id"]
            isOneToOne: false
            referencedRelation: "service_destinations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotes_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotes_rule_id_fkey"
            columns: ["rule_id"]
            isOneToOne: false
            referencedRelation: "pricing_rules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotes_slot_id_fkey"
            columns: ["slot_id"]
            isOneToOne: false
            referencedRelation: "collection_slots"
            referencedColumns: ["id"]
          },
        ]
      }
      receipts: {
        Row: {
          amount_kobo: number
          auth_user_id: string
          currency: string
          id: string
          issued_at: string
          payment_order_id: string
        }
        Insert: {
          amount_kobo: number
          auth_user_id: string
          currency: string
          id?: string
          issued_at?: string
          payment_order_id: string
        }
        Update: {
          amount_kobo?: number
          auth_user_id?: string
          currency?: string
          id?: string
          issued_at?: string
          payment_order_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "receipts_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "receipts_payment_order_id_fkey"
            columns: ["payment_order_id"]
            isOneToOne: true
            referencedRelation: "payment_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      refund_requests: {
        Row: {
          amount_kobo: number
          auth_user_id: string
          created_at: string
          id: string
          payment_order_id: string
          provider_refund_id: string | null
          reason: string
          state: string
        }
        Insert: {
          amount_kobo: number
          auth_user_id: string
          created_at?: string
          id?: string
          payment_order_id: string
          provider_refund_id?: string | null
          reason: string
          state?: string
        }
        Update: {
          amount_kobo?: number
          auth_user_id?: string
          created_at?: string
          id?: string
          payment_order_id?: string
          provider_refund_id?: string | null
          reason?: string
          state?: string
        }
        Relationships: [
          {
            foreignKeyName: "refund_requests_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "refund_requests_payment_order_id_fkey"
            columns: ["payment_order_id"]
            isOneToOne: false
            referencedRelation: "payment_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      rewards_ledger: {
        Row: {
          auth_user_id: string
          booking_id: string
          created_at: string
          id: string
          idempotency_key: string
          points: number
          reason: string
        }
        Insert: {
          auth_user_id: string
          booking_id: string
          created_at?: string
          id?: string
          idempotency_key: string
          points: number
          reason: string
        }
        Update: {
          auth_user_id?: string
          booking_id?: string
          created_at?: string
          id?: string
          idempotency_key?: string
          points?: number
          reason?: string
        }
        Relationships: [
          {
            foreignKeyName: "rewards_ledger_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "rewards_ledger_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
        ]
      }
      service_availability: {
        Row: {
          active: boolean
          area_name: string
          id: string
          service: string
        }
        Insert: {
          active?: boolean
          area_name: string
          id?: string
          service: string
        }
        Update: {
          active?: boolean
          area_name?: string
          id?: string
          service?: string
        }
        Relationships: []
      }
      service_destinations: {
        Row: {
          active: boolean
          authorization_reference: string
          category_id: string
          coverage_id: string
          id: string
          name: string
        }
        Insert: {
          active?: boolean
          authorization_reference: string
          category_id: string
          coverage_id: string
          id?: string
          name: string
        }
        Update: {
          active?: boolean
          authorization_reference?: string
          category_id?: string
          coverage_id?: string
          id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_destinations_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "waste_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_destinations_coverage_id_fkey"
            columns: ["coverage_id"]
            isOneToOne: false
            referencedRelation: "service_availability"
            referencedColumns: ["id"]
          },
        ]
      }
      support_tickets: {
        Row: {
          auth_user_id: string
          body: string
          created_at: string
          id: string
          status: string
        }
        Insert: {
          auth_user_id: string
          body: string
          created_at?: string
          id?: string
          status?: string
        }
        Update: {
          auth_user_id?: string
          body?: string
          created_at?: string
          id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_tickets_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
        ]
      }
      verification_applications: {
        Row: {
          auth_user_id: string
          created_at: string
          id: string
          review_reason: string | null
          reviewed_at: string | null
          state: Database["public"]["Enums"]["verification_state"]
          submitted_at: string | null
        }
        Insert: {
          auth_user_id: string
          created_at?: string
          id?: string
          review_reason?: string | null
          reviewed_at?: string | null
          state?: Database["public"]["Enums"]["verification_state"]
          submitted_at?: string | null
        }
        Update: {
          auth_user_id?: string
          created_at?: string
          id?: string
          review_reason?: string | null
          reviewed_at?: string | null
          state?: Database["public"]["Enums"]["verification_state"]
          submitted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "verification_applications_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
        ]
      }
      verification_documents: {
        Row: {
          application_id: string | null
          auth_user_id: string
          created_at: string
          id: string
          requirement_id: string
          storage_path: string
        }
        Insert: {
          application_id?: string | null
          auth_user_id: string
          created_at?: string
          id?: string
          requirement_id: string
          storage_path: string
        }
        Update: {
          application_id?: string | null
          auth_user_id?: string
          created_at?: string
          id?: string
          requirement_id?: string
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "verification_documents_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "verification_applications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "verification_documents_auth_user_id_fkey"
            columns: ["auth_user_id"]
            isOneToOne: false
            referencedRelation: "customer_accounts"
            referencedColumns: ["auth_user_id"]
          },
          {
            foreignKeyName: "verification_documents_requirement_id_fkey"
            columns: ["requirement_id"]
            isOneToOne: false
            referencedRelation: "verification_requirements"
            referencedColumns: ["id"]
          },
        ]
      }
      verification_requirements: {
        Row: {
          account_type: Database["public"]["Enums"]["customer_category"]
          active: boolean
          id: string
          label: string
        }
        Insert: {
          account_type: Database["public"]["Enums"]["customer_category"]
          active?: boolean
          id?: string
          label: string
        }
        Update: {
          account_type?: Database["public"]["Enums"]["customer_category"]
          active?: boolean
          id?: string
          label?: string
        }
        Relationships: []
      }
      waste_categories: {
        Row: {
          active: boolean
          hazardous: boolean
          id: string
          label: string
          preparation: string
          service: string
        }
        Insert: {
          active?: boolean
          hazardous?: boolean
          id?: string
          label: string
          preparation: string
          service: string
        }
        Update: {
          active?: boolean
          hazardous?: boolean
          id?: string
          label?: string
          preparation?: string
          service?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      cancel_booking: { Args: { booking: string }; Returns: undefined }
      create_booking: {
        Args: { idempotency: string; quote: string }
        Returns: {
          address_snapshot: Json
          auth_user_id: string
          created_at: string
          id: string
          idempotency_key: string
          organization_id: string | null
          payment_status: string
          quote_id: string
          requested_at: string
          service: string
          slot_id: string | null
          status: string
        }
        SetofOptions: {
          from: "*"
          to: "bookings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_organization: { Args: { org_name: string }; Returns: string }
      get_operational_audit: {
        Args: { before_id?: number }
        Returns: unknown[]
        SetofOptions: {
          from: "*"
          to: "audit_events"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      list_collection_slots: {
        Args: { address: string }
        Returns: {
          ends_at: string
          id: string
          starts_at: string
        }[]
      }
      prepare_payment: {
        Args: { booking: string }
        Returns: {
          amount_kobo: number
          auth_user_id: string
          authorization_url: string | null
          booking_id: string
          created_at: string
          currency: string
          id: string
          provider_reference: string
          provider_transaction_id: string | null
          status: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      receive_integration_event: {
        Args: {
          booking: string
          event_id: string
          event_payload: Json
          event_sequence: number
          kind: string
        }
        Returns: string
      }
      record_booking_outcome: {
        Args: { booking: string; evidence_reference: string; outcome: string }
        Returns: string
      }
      record_payment_outcome: {
        Args: { outcome: string; reference: string }
        Returns: string
      }
      record_verified_payment: {
        Args: {
          amount: number
          currency_code: string
          provider_id: string
          reference: string
        }
        Returns: string
      }
      record_verified_refund: {
        Args: { amount: number; provider_refund: string; reference: string }
        Returns: undefined
      }
      request_quote: {
        Args: {
          address: string
          category: string
          destination?: string
          prepared?: boolean
          quantity: number
          slot: string
          unit: string
        }
        Returns: {
          address_id: string | null
          address_snapshot: Json | null
          amount_kobo: number
          auth_user_id: string
          category_id: string | null
          created_at: string
          currency: string
          destination_id: string | null
          expires_at: string
          id: string
          items: Json
          organization_id: string | null
          preparation_confirmed: boolean
          quantity: number | null
          rule_id: string | null
          slot_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "quotes"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      request_refund: {
        Args: { payment: string; reason: string }
        Returns: string
      }
      reschedule_booking: {
        Args: { booking: string; new_slot: string }
        Returns: undefined
      }
      review_refund: {
        Args: { approval: boolean; note: string; refund: string }
        Returns: undefined
      }
      review_verification: {
        Args: {
          decision: Database["public"]["Enums"]["verification_state"]
          reason: string
          subject: string
        }
        Returns: undefined
      }
      save_address: {
        Args: {
          address_text: string
          coverage: string
          label: string
          organization?: string
        }
        Returns: string
      }
      set_organization_member: {
        Args: {
          enabled: boolean
          may_book: boolean
          member: string
          org: string
        }
        Returns: undefined
      }
      submit_verification_document: {
        Args: { object_path: string; requirement: string }
        Returns: undefined
      }
      update_support_ticket: {
        Args: { new_status: string; ticket: string }
        Returns: undefined
      }
      verify_address_coverage: {
        Args: { address: string; approved: boolean }
        Returns: undefined
      }
    }
    Enums: {
      customer_category: "household" | "estate" | "business"
      verification_state:
        | "not_started"
        | "submitted"
        | "under_review"
        | "corrections_required"
        | "approved"
        | "rejected"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      customer_category: ["household", "estate", "business"],
      verification_state: [
        "not_started",
        "submitted",
        "under_review",
        "corrections_required",
        "approved",
        "rejected",
      ],
    },
  },
} as const
