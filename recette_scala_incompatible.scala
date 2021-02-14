// -------------------------------------------------------------------------------- NOTEBOOK-CELL: CODE
import com.dataiku.dss.spark._
import org.apache.spark.SparkContext
import org.apache.spark.sql.SQLContext
import org.apache.spark.sql.functions._
import org.apache.spark.sql.expressions.Window
import org.apache.spark.sql.{Dataset, DataFrame}
import org.apache.spark.sql.Row

// -------------------------------------------------------------------------------- NOTEBOOK-CELL: CODE
val sparkConf    = DataikuSparkContext.buildSparkConf()
val sparkContext = SparkContext.getOrCreate(sparkConf)
val sqlContext   = new SQLContext(sparkContext)
val dkuContext   = DataikuSparkContext.getContext(sparkContext)

// -------------------------------------------------------------------------------- NOTEBOOK-CELL: CODE
//val fenetre = Window.partitionBy("kn_etablissement")

// Recipe inputs
val df = dkuContext.getDataFrame(sqlContext, "sav_pr00_ppx005_egcemp_etablissement")
    .select("td_datmaj","dd_datecreation","dc_trancheeffectif_id","kn_etablissement","dc_saisonnalite","dn_effectifreelentreprise","kn_entreprise","dc_enseigne","dc_nafrev2_id","kd_datemodification")
    .filter(col("td_datmaj")>="2020-03-01 00:00:00")
    .withColumn("countCol", lit(1))
    .select("dd_datecreation","dc_trancheeffectif_id","kn_etablissement","dc_saisonnalite","dn_effectifreelentreprise","kn_entreprise","dc_enseigne","dc_nafrev2_id","kd_datemodification","countCol")
    .groupBy("dd_datecreation","dc_trancheeffectif_id","kn_etablissement","dc_saisonnalite","dn_effectifreelentreprise","kn_entreprise","dc_enseigne","dc_nafrev2_id","kd_datemodification").sum("countCol")

// -------------------------------------------------------------------------------- NOTEBOOK-CELL: CODE
// Recipe outputs
dkuContext.save("sav_scala_on_egcemp_full", df);
