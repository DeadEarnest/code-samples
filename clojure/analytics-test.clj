 
(deftest analytics-by-category__counts-resolved-issues
  (let [token       (get-token-for :manager)
        category-id (:category-id (create-issue token))
        [result _] (get-analytics-by-category-latest token organization-id {})

        category-info
        (first-superset {:category-id category-id} (:analytics result))

        [issue-count resolved-issue-count]
        (vals (select-keys category-info [:count :count-resolved]))]

    (is (= 1 issue-count))
    (is (zero? resolved-issue-count))))

(deftest analytics-by-category__filters-by-category-id
  (let [token       (get-token-for :manager)
        filter-one     {:category-ids [1]}
        filter-three     {:category-ids [1 2 3]}
        [result-one _]  (get-analytics-by-category-latest token
                                                          organization-id
                                                          filter-one)
        [result-three _]  (get-analytics-by-category-latest token
                                                            organization-id
                                                            filter-three)]

    (is (= 1 (count (:analytics result-one))))
    (is (= 3 (count (:analytics result-three))))))




(defn get-last-issue-activity-id [issue-id]
  (->
   {:select :%max.activity_id
    :from   :issue-activities
    :where  [:= :issue-id issue-id]}
   honey/query first :max))

(defn add-interval-to-resolution-time [issue-id interval]
  (let [activity-id (get-last-issue-activity-id issue-id)]
    (honey/execute!
     {:update :issue-activities
      :set    {:created-at (sql/raw ["created_at + INTERVAL '" interval "'"])}
      :where  [:= :activity-id activity-id]})))

(defn get-avg-resolution-period-sec [token]
  (let [[{:keys [:avg-resolution-period-sec]} _]
        (get-analytics-by-treated-period-latest token organization-id)]
    avg-resolution-period-sec))




(deftest analytics-by-treated-period__includes-avg-resolution-time
  (let [token (get-token-for :manager)
        issue-id-1 (:issue-id (create-issue token))
        issue-id-2 (:issue-id (create-issue token))
        period-1 (get-avg-resolution-period-sec token)
        _ (do (mark-treated token issue-id-1) (mark-treated token issue-id-2))
        _ (add-interval-to-resolution-time issue-id-2 "180 seconds")
        period-2 (get-avg-resolution-period-sec token)]

    (testing "Nil, when no resolved issues"
      (is (nil? period-1)))

    (testing "Avg time, when resolved issues exist"
      (is (= 90 period-2)))))
