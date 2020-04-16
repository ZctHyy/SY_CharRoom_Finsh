%%----------------------------------------------------
%% 公共定义文件
%% (不要随意在此添加新的定义)
%% 
%% @author Jange
%%----------------------------------------------------
%% 数字型的bool值
-define(false, 0).
-define(true, 1).

%% 语言翻译，返回给玩家的文本信息需要经过此宏的转换
-define(T(Text), <<Text/utf8>>).

%% 自定格式信息输出，相当于io:format，支持中文输出
-define(P(F, A),
    case os:type() of
        {win32, _} ->
            io:format("~ts", [io_lib:format(F, A)]);
        _ ->
            io:format("~ts", [io_lib:format(F, A)])
    end).
-define(P(F), ?P(F, [])).
-define(P(T, F, A), util:printf(T, F, A)).

%% 按固定格式输出调试信息，非debug模式下自动关闭
-ifdef(debug).
-define(DEBUG(Msg), ?P(Msg)).
-define(DEBUG(F, A), ?P(F, A)).
-else.
-define(DEBUG(Msg), ok).
-define(DEBUG(F, A), ok).
-endif.

%% 控制台字体颜色
-define(RED, "\e[1;31m").
-define(PURPLE, "\e[35;1m").
-define(YELLOW, "\e[1;33m").
-define(GREEN, "\e[1;32m").
-define(DEF_COLOR, "\e[0;38m").

%% 带catch的gen_server:call/2，返回{error, timeout} | {error, noproc} | {error, term()} | term() | {exit, normal}
%% 此宏只会返回简略信息，如果需要获得更详细的信息，请使用以下方式自行处理:
%% case catch gen_server:call(Pid, Request)
-define(CALL(_Call_Pid, _Call_Request, _Time_Out),
    case catch gen_server:call(_Call_Pid, _Call_Request, _Time_Out) of
        {'EXIT', {timeout, _}} -> {error, timeout};
        {'EXIT', {noproc, _}} -> {error, noproc};
        {'EXIT', {normal, _}} -> {error, exit};
        {'EXIT', _Call_Err} -> {error, _Call_Err};
        _Call_Return -> _Call_Return
    end
).
-define(CALL(_Call_Pid, _Call_Request), ?CALL(_Call_Pid, _Call_Request, 10000)).

%% 带catch的gen_fsm:sync_send_all_state_event/2
%% 返回{error, timeout} | {error, noproc} | {error, term()} | term() | {exit, normal}
-define(FSM_CALL(_Call_Pid, _Call_Request, _Time_Out),
    case catch gen_fsm:sync_send_all_state_event(_Call_Pid, _Call_Request, _Time_Out) of
        {'EXIT', {timeout, _}} -> {error, timeout};
        {'EXIT', {noproc, _}} -> {error, noproc};
        {'EXIT', {normal, _}} -> {error, exit};
        {'EXIT', _Call_Err} -> {error, _Call_Err};
        _Call_Return -> _Call_Return
    end
).
-define(FSM_CALL(_Call_Pid, _Call_Request), ?FSM_CALL(_Call_Pid, _Call_Request, 10000)).

%% 未实现的函数请加入下面这个宏到函数体中
-define(NYI, io:format("*** NYI ~p ~p~n", [?MODULE, ?LINE]), exit(nyi)).

%% 将record转换成tuplelist
-define(record_to_tuplelist(Rec, Ref), lists:zip([record_name | record_info(fields, Rec)], tuple_to_list(Ref))).
