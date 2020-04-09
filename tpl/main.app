{application, main, 
    [
        {description, "main server"}
        ,{vsn, "1"}
        ,{registered, [main]}
        ,{applications, [kernel, stdlib, crypto]}
        ,{mod, {main, []}}
        ,{env, 
            [
                {cookie, '<#cookie#>'}
                ,{host_id, <#zone_id#>}
                ,{platform, <<"<#platform#>">>}
                ,{host, "<#host#>"}
                ,{port, 8001}
                ,{tcp_acceptor_num, 2}
                ,{tcp_options, [
                        binary
                        ,{packet, 0}
                        ,{active, false}
                        ,{reuseaddr, true}
                        ,{nodelay, false}
                        ,{delay_send, true}
                        ,{exit_on_close, false}
                        ,{send_timeout, 10000}
                        ,{send_timeout_close, false}
                    ]
                }
            ]
        }
    ]
}.
