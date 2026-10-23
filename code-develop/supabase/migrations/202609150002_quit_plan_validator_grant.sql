begin;

grant execute on function public.is_valid_support_people(jsonb)
to authenticated;
grant execute on function public.is_unique_text_array(text[])
to authenticated;

commit;
