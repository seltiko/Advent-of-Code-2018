with inputs as(
  select '177, 51
350, 132
276, 139
249, 189
225, 137
337, 354
270, 147
182, 329
118, 254
174, 280
42, 349
96, 341
236, 46
84, 253
292, 143
253, 92
224, 137
209, 325
243, 195
208, 337
197, 42
208, 87
45, 96
64, 295
266, 248
248, 298
194, 261
157, 74
52, 248
243, 201
242, 178
140, 319
69, 270
314, 302
209, 212
237, 217
86, 294
295, 144
248, 206
157, 118
155, 146
331, 40
247, 302
250, 95
193, 214
345, 89
183, 206
121, 169
79, 230
88, 155'::text as inputs
)

,split as (
  select regexp_split_to_table(inputs,'\n')::text as inputs
  from inputs
)
,id_split as (

  select row_number() over() as row_id, inputs as raw_inputs,
    ((regexp_matches(inputs,'^(\d+),'))[1])::int as y,
    ((regexp_matches(inputs,', (\d+)$'))[1])::int as x,
    ('('||((regexp_matches(inputs,', (\d+)$'))[1])||','||((regexp_matches(inputs, '^(\d+),')) [1])||')')::point as xy
  from split
)
,edges as(
  select min(x) as minx, max(x) as maxx, min(y) as miny, max(y) as maxy
  from id_split i
)

-- select *, min(x) over(), max(x) over(), min(y) over(), max(y) over()
--   from id_split i

, grid as (
    select
       row_number() over() as grid_id,
      ('(' || x :: text || ',' || y :: text || ')') :: point as grid,
      *
    from (
           select
             generate_series((select minx
                              from edges), (select maxx
                                            from edges)) as x,
             y
           from (select generate_series((select miny
                                         from edges), (select maxy
                                                       from edges)) as y) y
         ) xy
)
,min_dist as (
    select --distinct on (grid_id)
      g.grid_id,
      g.grid,
      g.x as gx,
      g.y as gy,
      i.row_id,
      i.x as ix,
      i.y as iy,
      i.xy,
      height(box(g.grid, i.xy)) + width(box(g.grid, i.xy)) dist
    from grid g
      full join id_split i
        on true
--     order by grid_id,
--       dist asc
)
  ,true_min_dist as (
  select *
  from (
    select
      m.*,
      count(1)
      over (
        partition by m.grid_id ) as dup_count
    from min_dist m
      left join min_dist m2
        on m2.grid_id = m.grid_id
           and m2.dist < m.dist
    where m2.grid_id is null
  ) t
  where dup_count = 1
)
,infinites as (
    select *
    from id_split i
      inner join true_min_dist md
      using (row_id)
      inner join edges e
        on e.maxx = gx or e.maxy = gy
           or e.minx = gx or e.miny = gy
)

,part1 as (
    select
      --   *
      m.row_id,
      m.ix,
      m.iy,
      count(1)
    from true_min_dist m
      left join infinites i
        on i.row_id = m.row_id
    where i.row_id is null
    group by 1, 2, 3
    order by 4 desc
)
select count(1)
from (
  select
    grid_id,
    sum(dist)
  from min_dist m
  group by 1
  having sum(dist) < 10000
)t
;


