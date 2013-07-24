Railscookies::Application.config.session_store :redis_store_json,
                                               key: "_response_session",
                                               strategy: :json_session,
                                               domain: :all,
                                               servers: {
                                                   host: :localhost,
                                                   port: 6379
                                               }
