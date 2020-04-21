%%----------------------------------------------------
%% @doc 用户数据结构
%%
%% @author Jange
%% @end
%%----------------------------------------------------


-record(user1,{
        %%进程Pid
    username
	,pid
	%%通信socket
	,socket 
    %%当前状态
	,status
    %%｛本次登陆时间，上次下线时间｝
    ,time_info
	,location
         }).
