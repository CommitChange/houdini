# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later


module QueryProfiles

  def self.for_admin(params)
     expr = Qx.select(
        'profiles.id',
        'profiles.first_name',
        'profiles.last_name',
        'profiles.phone',
        'profiles.city',
        'profiles.created_at::date::text AS created_at',
        'profiles.updated_at::date::text AS updated_at',
        'users.email as email',
        'users.name as name',
        'users.confirmed_at AS is_confirmed'
        )
      .from(:profiles)
      .add_left_join("users", "profiles.user_id=users.id")
      .order_by("profiles.id DESC")
      .paginate(params[:page].to_i, params[:page_length].to_i)

      if params[:search].present?
        expr = expr.where(%Q(
          profiles.name LIKE $search
          OR users.email LIKE $search
          OR users.name LIKE $search
        ), search: '%' + params[:search].downcase + '%')
      end

      return expr.execute
  end
end
