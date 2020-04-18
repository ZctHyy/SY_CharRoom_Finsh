%%----------------------------------------------------
%% @doc 客户端数据结构定义
%%
%% @author Jange
%% @end
%%----------------------------------------------------


-record(croom,{
        %%进程Pid
        name
		%%是否配置客厅，不配置客厅，则每个人进入默认是客厅，然后退出房间就进入客厅，或者换房。
        %%当前状态,首先，大众客厅永远不会消失，是否因为没人而消失需要考虑。
		,status,
		%%房间成员列表
		memberList=[]
         }).
