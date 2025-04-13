function get_MPMQ(R,X,_BRANCH_SET)

    M_P = Dict() #to be multiplied by P
    M_Q = Dict() #to be multiplied by Q

    for (i,j) in _BRANCH_SET

        M_P[(i,j),(:a,:a)] = -2*R[(i,j),(:a,:a)]
        M_P[(i,j),(:a,:b)] = R[(i,j),(:a,:b)]-sqrt(3)*X[(i,j),(:a,:b)]
        M_P[(i,j),(:a,:c)] = R[(i,j),(:a,:c)]+sqrt(3)*X[(i,j),(:a,:c)]

        M_P[(i,j),(:b,:a)] = R[(i,j),(:a,:b)]+sqrt(3)*X[(i,j),(:a,:b)]
        M_P[(i,j),(:b,:b)] = -2*R[(i,j),(:b,:b)]
        M_P[(i,j),(:b,:c)] = R[(i,j),(:b,:c)]-sqrt(3)*X[(i,j),(:b,:c)]

        M_P[(i,j),(:c,:a)] = R[(i,j),(:a,:c)]-sqrt(3)*X[(i,j),(:a,:c)]
        M_P[(i,j),(:c,:b)] = R[(i,j),(:b,:c)]+sqrt(3)*X[(i,j),(:b,:c)]
        M_P[(i,j),(:c,:c)] = -2*R[(i,j),(:c,:c)]

        M_Q[(i,j),(:a,:a)] = -2*X[(i,j),(:a,:a)]
        M_Q[(i,j),(:a,:b)] = X[(i,j),(:a,:b)]+sqrt(3)*R[(i,j),(:a,:b)]
        M_Q[(i,j),(:a,:c)] = X[(i,j),(:a,:c)]-sqrt(3)*R[(i,j),(:a,:c)]

        M_Q[(i,j),(:b,:a)] = X[(i,j),(:a,:b)]-sqrt(3)*R[(i,j),(:a,:b)]
        M_Q[(i,j),(:b,:b)] = -2*X[(i,j),(:b,:b)]
        M_Q[(i,j),(:b,:c)] = X[(i,j),(:b,:c)]+sqrt(3)*R[(i,j),(:b,:c)]

        M_Q[(i,j),(:c,:a)] = X[(i,j),(:a,:c)]+sqrt(3)*R[(i,j),(:a,:c)]
        M_Q[(i,j),(:c,:b)] = X[(i,j),(:b,:c)]-sqrt(3)*R[(i,j),(:b,:c)]
        M_Q[(i,j),(:c,:c)] = -2*X[(i,j),(:c,:c)]

    end

    return M_P, M_Q

end
