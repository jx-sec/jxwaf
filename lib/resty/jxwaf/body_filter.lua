


if ngx.ctx.log_response  and (not ngx.ctx.resp_body) then
  local resp_body = ngx.arg[1] or ""
  ngx.ctx.resp_body = resp_body
end