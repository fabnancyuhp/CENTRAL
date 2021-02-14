import com.dataiku.dss.spark._
import org.apache.spark.SparkContext
import org.apache.spark.sql.functions._
import org.apache.spark.sql.hive.HiveContext

// -------------------------------------------------------------------------------- NOTEBOOK-CELL: CODE
val sparkConf    = DataikuSparkContext.buildSparkConf()
val sparkContext = SparkContext.getOrCreate(sparkConf)
val hiveContext = new HiveContext(sparkContext)
val dkuContext   = DataikuSparkContext.getContext(sparkContext)

// -------------------------------------------------------------------------------- NOTEBOOK-CELL: CODE
// Recipe inputs
val df_hive_dataset = dkuContext.getDataFrame(hiveContext, "sav_pr00_ppx005_egcemp_etablissement")

// -------------------------------------------------------------------------------- NOTEBOOK-CELL: CODE
val sav_scala_hiveContext = df_hive_dataset.select("td_datmaj","dd_datecreation","dc_trancheeffectif_id","kn_etablissement","dc_saisonnalite","dn_effectifreelentreprise","kn_entreprise","dc_enseigne","dc_nafrev2_id","kd_datemodification")
     .filter(col("td_datmaj")>="2020-03-01 00:00:00")
     .withColumn("countCol", lit(1))
     .select("dd_datecreation","dc_trancheeffectif_id","kn_etablissement","dc_saisonnalite","dn_effectifreelentreprise","kn_entreprise","dc_enseigne","dc_nafrev2_id","kd_datemodification","countCol")
     .groupBy("dd_datecreation","dc_trancheeffectif_id","kn_etablissement","dc_saisonnalite","dn_effectifreelentreprise","kn_entreprise","dc_enseigne","dc_nafrev2_id","kd_datemodification")
     .sum("countCol")

// -------------------------------------------------------------------------------- NOTEBOOK-CELL: CODE
// The returned Map must contain (dataset name -> dataframe) pairs
Map("sav_scala_hiveContext" -> sav_scala_hiveContext)
