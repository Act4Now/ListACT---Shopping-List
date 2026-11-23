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
      household_invitations: {
        Row: {
          accepted_at: string | null
          created_at: string
          email: string
          expires_at: string
          household_id: string
          id: string
          invited_by: string
          token_hash: string
        }
        Insert: {
          accepted_at?: string | null
          created_at?: string
          email: string
          expires_at: string
          household_id: string
          id?: string
          invited_by: string
          token_hash: string
        }
        Update: {
          accepted_at?: string | null
          created_at?: string
          email?: string
          expires_at?: string
          household_id?: string
          id?: string
          invited_by?: string
          token_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "household_invitations_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      household_join_links: {
        Row: {
          created_at: string
          created_by: string
          household_id: string
          revoked_at: string | null
          token_hash: string
        }
        Insert: {
          created_at?: string
          created_by: string
          household_id: string
          revoked_at?: string | null
          token_hash: string
        }
        Update: {
          created_at?: string
          created_by?: string
          household_id?: string
          revoked_at?: string | null
          token_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "household_join_links_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: true
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      household_members: {
        Row: {
          household_id: string
          joined_at: string
          role: string
          user_id: string
        }
        Insert: {
          household_id: string
          joined_at?: string
          role?: string
          user_id: string
        }
        Update: {
          household_id?: string
          joined_at?: string
          role?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "household_members_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      households: {
        Row: {
          city: string | null
          created_at: string
          created_by: string
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          city?: string | null
          created_at?: string
          created_by: string
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          city?: string | null
          created_at?: string
          created_by?: string
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      list_item_price_overrides: {
        Row: {
          currency: string
          personal_unit_price: number
          shopping_item_id: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          currency?: string
          personal_unit_price: number
          shopping_item_id: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          currency?: string
          personal_unit_price?: number
          shopping_item_id?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "list_item_price_overrides_shopping_item_id_fkey"
            columns: ["shopping_item_id"]
            isOneToOne: false
            referencedRelation: "shopping_items"
            referencedColumns: ["id"]
          },
        ]
      }
      price_estimates: {
        Row: {
          city: string
          created_at: string
          currency: string
          estimated_unit_price: number
          household_id: string
          id: string
          match_type: string
          observed_at: string
          sample_count: number
          shopping_item_id: string
          source_count: number
        }
        Insert: {
          city: string
          created_at?: string
          currency?: string
          estimated_unit_price: number
          household_id: string
          id?: string
          match_type: string
          observed_at: string
          sample_count?: number
          shopping_item_id: string
          source_count?: number
        }
        Update: {
          city?: string
          created_at?: string
          currency?: string
          estimated_unit_price?: number
          household_id?: string
          id?: string
          match_type?: string
          observed_at?: string
          sample_count?: number
          shopping_item_id?: string
          source_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "price_estimates_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "price_estimates_shopping_item_id_fkey"
            columns: ["shopping_item_id"]
            isOneToOne: true
            referencedRelation: "shopping_items"
            referencedColumns: ["id"]
          },
        ]
      }
      price_observations: {
        Row: {
          created_at: string
          currency: string
          id: string
          match_type: string
          observed_at: string
          price: number
          product_id: string
          source_id: string
          source_url: string | null
          store_location_id: string
        }
        Insert: {
          created_at?: string
          currency?: string
          id?: string
          match_type: string
          observed_at: string
          price: number
          product_id: string
          source_id: string
          source_url?: string | null
          store_location_id: string
        }
        Update: {
          created_at?: string
          currency?: string
          id?: string
          match_type?: string
          observed_at?: string
          price?: number
          product_id?: string
          source_id?: string
          source_url?: string | null
          store_location_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "price_observations_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "price_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "price_observations_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "price_sources"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "price_observations_store_location_id_fkey"
            columns: ["store_location_id"]
            isOneToOne: false
            referencedRelation: "store_locations"
            referencedColumns: ["id"]
          },
        ]
      }
      price_products: {
        Row: {
          brand: string | null
          category: string | null
          created_at: string
          ean: string | null
          id: string
          name: string
          normalized_name: string
          package_quantity: number | null
          package_unit: string | null
        }
        Insert: {
          brand?: string | null
          category?: string | null
          created_at?: string
          ean?: string | null
          id?: string
          name: string
          normalized_name: string
          package_quantity?: number | null
          package_unit?: string | null
        }
        Update: {
          brand?: string | null
          category?: string | null
          created_at?: string
          ean?: string | null
          id?: string
          name?: string
          normalized_name?: string
          package_quantity?: number | null
          package_unit?: string | null
        }
        Relationships: []
      }
      price_sources: {
        Row: {
          code: string
          created_at: string
          id: string
          is_enabled: boolean
          license_name: string | null
          name: string
          reuse_permitted: boolean
          source_url: string | null
          terms_url: string | null
          terms_verified_at: string | null
        }
        Insert: {
          code: string
          created_at?: string
          id?: string
          is_enabled?: boolean
          license_name?: string | null
          name: string
          reuse_permitted?: boolean
          source_url?: string | null
          terms_url?: string | null
          terms_verified_at?: string | null
        }
        Update: {
          code?: string
          created_at?: string
          id?: string
          is_enabled?: boolean
          license_name?: string | null
          name?: string
          reuse_permitted?: boolean
          source_url?: string | null
          terms_url?: string | null
          terms_verified_at?: string | null
        }
        Relationships: []
      }
      product_similarity_groups: {
        Row: {
          category: string | null
          created_at: string
          id: string
          label: string
          unit: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          id?: string
          label: string
          unit: string
        }
        Update: {
          category?: string | null
          created_at?: string
          id?: string
          label?: string
          unit?: string
        }
        Relationships: []
      }
      product_similarity_members: {
        Row: {
          group_id: string
          product_id: string
        }
        Insert: {
          group_id: string
          product_id: string
        }
        Update: {
          group_id?: string
          product_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_similarity_members_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "product_similarity_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_similarity_members_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "price_products"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          city: string | null
          created_at: string
          display_name: string | null
          font_size: number
          id: string
          updated_at: string
        }
        Insert: {
          city?: string | null
          created_at?: string
          display_name?: string | null
          font_size?: number
          id: string
          updated_at?: string
        }
        Update: {
          city?: string | null
          created_at?: string
          display_name?: string | null
          font_size?: number
          id?: string
          updated_at?: string
        }
        Relationships: []
      }
      shopping_items: {
        Row: {
          created_at: string
          created_by: string
          id: string
          is_purchased: boolean
          list_id: string
          name: string
          price_currency: string
          purchased_at: string | null
          quantity: number
          store_id: string | null
          unit: string
          unit_price: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string
          id?: string
          is_purchased?: boolean
          list_id: string
          name: string
          price_currency?: string
          purchased_at?: string | null
          quantity?: number
          store_id?: string | null
          unit?: string
          unit_price?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string
          id?: string
          is_purchased?: boolean
          list_id?: string
          name?: string
          price_currency?: string
          purchased_at?: string | null
          quantity?: number
          store_id?: string | null
          unit?: string
          unit_price?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shopping_items_list_id_fkey"
            columns: ["list_id"]
            isOneToOne: false
            referencedRelation: "shopping_lists"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shopping_items_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      shopping_lists: {
        Row: {
          archived_at: string | null
          created_at: string
          created_by: string
          household_id: string
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          archived_at?: string | null
          created_at?: string
          created_by?: string
          household_id: string
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          archived_at?: string | null
          created_at?: string
          created_by?: string
          household_id?: string
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shopping_lists_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      store_locations: {
        Row: {
          address: string | null
          city: string
          created_at: string
          id: string
          latitude: number | null
          longitude: number | null
          postal_code: string | null
          source_id: string | null
          store_id: string
        }
        Insert: {
          address?: string | null
          city: string
          created_at?: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          postal_code?: string | null
          source_id?: string | null
          store_id: string
        }
        Update: {
          address?: string | null
          city?: string
          created_at?: string
          id?: string
          latitude?: number | null
          longitude?: number | null
          postal_code?: string | null
          source_id?: string | null
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "store_locations_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "price_sources"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "store_locations_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      stores: {
        Row: {
          created_at: string
          created_by: string | null
          household_id: string | null
          id: string
          is_active: boolean
          is_system: boolean
          name: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          household_id?: string | null
          id?: string
          is_active?: boolean
          is_system?: boolean
          name: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          household_id?: string | null
          id?: string
          is_active?: boolean
          is_system?: boolean
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "stores_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      accept_household_invitation: {
        Args: { p_token: string }
        Returns: string
      }
      accept_household_join_link: {
        Args: { p_household_id: string; p_token: string }
        Returns: string
      }
      add_shopping_item: {
        Args: {
          p_list_id: string
          p_name: string
          p_quantity?: number
          p_unit?: string
        }
        Returns: {
          created_at: string
          created_by: string
          id: string
          is_purchased: boolean
          list_id: string
          name: string
          price_currency: string
          purchased_at: string | null
          quantity: number
          store_id: string | null
          unit: string
          unit_price: number | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "shopping_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      add_shopping_items_bulk: {
        Args: { p_items: Json; p_list_id: string }
        Returns: Json
      }
      create_household: {
        Args: { p_city?: string; p_name: string }
        Returns: string
      }
      create_household_join_link: {
        Args: { p_household_id: string; p_token: string }
        Returns: undefined
      }
      remove_household_member: {
        Args: { p_household_id: string; p_user_id: string }
        Returns: undefined
      }
      revoke_household_join_link: {
        Args: { p_household_id: string }
        Returns: undefined
      }
      transfer_household_ownership: {
        Args: { p_household_id: string; p_new_owner_id: string }
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
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
    Enums: {},
  },
} as const
