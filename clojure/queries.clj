 
(defn- get-day [timestamp]
  (sql/call :int8 (sql/call :date_part "day" timestamp)))

(defn get-issue-resolution-ids-query [params]
  (let [issues-query
        (-> (assoc-in params [:filters :statuses] [:Resolved])
            (make-find-organization-issues-query))]
    (sql/build {:select   [:ia.issue-id
                           [:%max.ia.activity-id :activity-id]]
                :from     [[:issue-activities :ia]]
                :join     [[:issue-resolves :ir]
                           [:= :ir.activity-id :ia.activity-id]
                           [issues-query :i]
                           [:= :i.issue-id :ia.issue-id]]
                :group-by [:ia.issue-id]})))

(defn get-time-to-resolution-query [params select-clause]
  (let [issue-resolution-ids (get-issue-resolution-ids-query params)]
    (sql/build {:select [select-clause]
                :from   [[issue-resolution-ids :ir-id]]
                :join   [[:issue-activities :ia]
                         [:= :ia.activity-id :ir-id.activity-id]
                         [:issues :i]
                         [:= :i.issue-id :ir-id.issue-id]]})))

(defn get-days-to-resolution-query [params]
  (get-time-to-resolution-query
   params
   [(get-day (sql/call :- :ia.created-at :i.created-at)) :days]))

(defn get-avg-resolution-period-sec [params]
  (->
   (get-time-to-resolution-query
    params
    [(sql/raw ["avg(extract(epoch from (ia.created_at - i.created_at)))::int"])
     :seconds])
   honey/query first :seconds))

(defn create-resolution-periods-query [params]
  (let [periods-filter (get-in params [:filters :treated-periods])]
    (-> {:select [[(sql/call :int8range :column1 :column2) :period]]
         :from [[{:values periods-filter} :tmp-for-periods]]}
        sql/build)))

(defn get-analytics-by-treated-period [params]
  (let [days-to-resolution (get-days-to-resolution-query params)
        resolution-periods (create-resolution-periods-query params)]
    (honey/query
     {:select    [[(sql/call :upper :period) :upper-bound]
                  [(sql/call :lower :period) :lower-bound]
                  :%count.dtr.days]
      :from      [[resolution-periods :pq]]
      :left-join [[days-to-resolution :dtr] [:in-range :pq.period :dtr.days]]
      :group-by  :pq.period
      :order-by  :pq.period})))
